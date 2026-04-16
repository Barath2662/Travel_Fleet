const { body } = require('express-validator');
const mongoose = require('mongoose');
const Payment = require('../models/Payment');
const Bill = require('../models/Bill');

const paymentValidation = [
  body('billId').isMongoId(),
  body('amount').isFloat({ gt: 0 }),
  body('status').optional().isIn(['pending', 'paid']),
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

const recomputeBillPaymentStatus = async (billId, session) => {
  const billQuery = Bill.findById(billId);
  const paidAggregateQuery = Payment.aggregate([
    { $match: { billId: new mongoose.Types.ObjectId(String(billId)), status: 'paid' } },
    { $group: { _id: '$billId', totalPaid: { $sum: '$amount' } } },
  ]);

  if (session && session.inTransaction()) {
    billQuery.session(session);
    paidAggregateQuery.session(session);
  }

  const [bill, paidAggregate] = await Promise.all([billQuery, paidAggregateQuery]);

  if (!bill) {
    return null;
  }

  const totalPaid = paidAggregate.length ? Number(paidAggregate[0].totalPaid) : 0;
  const payableAmount = Number(bill.payableAmount || 0);

  if (totalPaid <= 0) {
    bill.paymentStatus = 'pending';
  } else if (totalPaid < payableAmount) {
    bill.paymentStatus = 'partial';
  } else {
    bill.paymentStatus = 'paid';
  }

  await bill.save({ session: session && session.inTransaction() ? session : undefined });
  return bill;
};

const createPayment = async (req, res) => {
  const { billId, amount, status, notes, idempotencyKey } = req.body;

  const session = await Payment.startSession();
  let paymentDoc = null;

  try {
    await runWithOptionalTransaction(session, async () => {
      const bill = session.inTransaction()
        ? await Bill.findById(billId).session(session)
        : await Bill.findById(billId);
      if (!bill) {
        res.status(404);
        throw new Error('Bill not found');
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
            amount: Number(amount),
            status: status || 'pending',
            notes,
            idempotencyKey,
            paidAt: (status || 'pending') === 'paid' ? new Date() : null,
            updatedBy: req.user._id,
          },
        ],
        { session: session.inTransaction() ? session : undefined }
      ).then((docs) => docs[0]);

      await recomputeBillPaymentStatus(billId, session);
    });
  } finally {
    await session.endSession();
  }

  res.status(201).json(paymentDoc);
};

const getPayments = async (_req, res) => {
  const payments = await Payment.find().populate('billId').sort({ createdAt: -1 });
  res.json(payments);
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

  Object.assign(payment, {
    ...req.body,
    amount: req.body.amount !== undefined ? Number(req.body.amount) : payment.amount,
  });
  payment.updatedBy = req.user._id;
  if (payment.status === 'paid' && !payment.paidAt) {
    payment.paidAt = new Date();
  } else if (payment.status !== 'paid') {
    payment.paidAt = null;
  }

  const session = await Payment.startSession();
  try {
    await runWithOptionalTransaction(session, async () => {
      await payment.save({ session: session.inTransaction() ? session : undefined });
      await recomputeBillPaymentStatus(payment.billId, session);
    });
  } finally {
    await session.endSession();
  }

  res.json(payment);
};

module.exports = { paymentValidation, createPayment, getPayments, updatePayment };
