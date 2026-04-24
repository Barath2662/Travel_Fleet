const { body } = require('express-validator');
const Payment = require('../models/Payment');
const Bill = require('../models/Bill');
const { syncBillFromPayments } = require('../services/billConsistencyService');

const paymentValidation = [
  body('billId').isMongoId(),
  body('amount').isFloat({ gt: 0 }),
  body('status').optional().isIn(['pending', 'paid']),
  body('mode').optional().isIn(['partial', 'full', 'remaining']),
  body('idempotencyKey').optional().isString(),
];

const runWithOptionalTransaction = async (session, work) => {
  try {
    await session.withTransaction(work);
  } catch (error) {
    if (String(error.message || '').includes('Transaction numbers are only allowed')) {
      await work();
      return;
    }
    throw error;
  }
};

const createPayment = async (req, res) => {
  const { billId, amount, notes, idempotencyKey } = req.body;

  const session = await Payment.startSession();
  let paymentDoc = null;
  let updatedBillDoc = null;

  try {
    await runWithOptionalTransaction(session, async () => {
      const bill = session.inTransaction()
        ? await Bill.findById(billId).session(session)
        : await Bill.findById(billId);
      if (!bill) {
        res.status(404);
        throw new Error('Bill not found');
      }

      await syncBillFromPayments({ bill, session });

      const requestedAmount = Number(amount);
      if (!Number.isFinite(requestedAmount) || requestedAmount <= 0) {
        res.status(400);
        throw new Error('Payment amount must be greater than 0');
      }

      const remainingBeforePayment = Number(bill.remainingAmount ?? bill.payableAmount ?? 0);
      if (remainingBeforePayment <= 0) {
        res.status(400);
        throw new Error('Bill is already fully paid');
      }

      if (requestedAmount > remainingBeforePayment) {
        res.status(400);
        throw new Error(`Payment exceeds remaining amount (${remainingBeforePayment.toFixed(2)})`);
      }

      if (idempotencyKey) {
        const existingByKey = session.inTransaction()
          ? await Payment.findOne({ idempotencyKey }).session(session)
          : await Payment.findOne({ idempotencyKey });
        if (existingByKey) {
          res.status(409);
          throw new Error('Duplicate payment request');
        }
      }

      paymentDoc = await Payment.create(
        [
          {
            billId,
            amount: requestedAmount,
            status: 'paid',
            notes,
            idempotencyKey,
            paidAt: new Date(),
            updatedBy: req.user._id,
          },
        ],
        { session: session.inTransaction() ? session : undefined }
      ).then((docs) => docs[0]);

      const scopedBill = session.inTransaction()
        ? await Bill.findById(billId).session(session)
        : await Bill.findById(billId);
      updatedBillDoc = await syncBillFromPayments({ bill: scopedBill, session });
    });
  } finally {
    await session.endSession();
  }

  res.status(201).json({
    payment: paymentDoc,
    bill: updatedBillDoc,
  });
};

const getPayments = async (_req, res) => {
  const payments = await Payment.find()
    .populate('billId', 'billCode customerName payableAmount paidAmount remainingAmount paymentStatus')
    .sort({ createdAt: -1 });

  const billsToSync = new Map();
  for (const payment of payments) {
    if (!payment.billId || !payment.billId._id) {
      continue;
    }
    billsToSync.set(String(payment.billId._id), payment.billId);
  }

  for (const bill of billsToSync.values()) {
    await syncBillFromPayments({ bill });
  }

  const refreshedPayments = await Payment.find()
    .populate('billId', 'billCode customerName payableAmount paidAmount remainingAmount paymentStatus')
    .sort({ createdAt: -1 });

  res.json(refreshedPayments);
};

const updatePayment = async (req, res) => {
  const payment = await Payment.findById(req.params.id);
  if (!payment) {
    res.status(404);
    throw new Error('Payment not found');
  }

  if (req.body.amount !== undefined && (!Number.isFinite(Number(req.body.amount)) || Number(req.body.amount) <= 0)) {
    res.status(400);
    throw new Error('Payment amount must be greater than 0');
  }

  const bill = await Bill.findById(payment.billId);
  if (!bill) {
    res.status(404);
    throw new Error('Bill not found for payment');
  }

  const nextAmount = req.body.amount !== undefined ? Number(req.body.amount) : payment.amount;
  const currentPaidWithoutThis = Math.max(Number(bill.paidAmount || 0) - Number(payment.status === 'paid' ? payment.amount : 0), 0);
  const maxAllowed = Math.max(Number(bill.payableAmount || 0) - currentPaidWithoutThis, 0);

  if (nextAmount > maxAllowed) {
    res.status(400);
    throw new Error(`Updated amount exceeds remaining allowable amount (${maxAllowed.toFixed(2)})`);
  }

  Object.assign(payment, {
    ...req.body,
    amount: req.body.amount !== undefined ? Number(req.body.amount) : payment.amount,
    status: 'paid',
  });
  payment.updatedBy = req.user._id;
  payment.paidAt = payment.paidAt || new Date();

  const session = await Payment.startSession();
  let updatedBillDoc = null;
  try {
    await runWithOptionalTransaction(session, async () => {
      await payment.save({ session: session.inTransaction() ? session : undefined });
      const scopedBill = session.inTransaction()
        ? await Bill.findById(payment.billId).session(session)
        : await Bill.findById(payment.billId);
      updatedBillDoc = await syncBillFromPayments({ bill: scopedBill, session });
    });
  } finally {
    await session.endSession();
  }

  res.json({
    payment,
    bill: updatedBillDoc,
  });
};

module.exports = { paymentValidation, createPayment, getPayments, updatePayment };
