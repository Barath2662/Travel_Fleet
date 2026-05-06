const Payment = require('../models/Payment');
const BillSequence = require('../models/BillSequence');

const formatBillCode = (year, sequence) => {
  const yy = String(Number(year) % 100).padStart(2, '0');
  const seq = String(Number(sequence)).padStart(3, '0');
  return `samp-${yy}${seq}`;
};

const isInvalidBillCode = (billCode) => {
  const value = String(billCode || '').trim();
  return !/^samp-\d{5}$/i.test(value);
};

const ensureBillSequence = async ({ bill, session }) => {
  if (!bill) return null;
  if (Number(bill.billYear) && Number(bill.billSequence)) {
    return { billYear: Number(bill.billYear), billSequence: Number(bill.billSequence) };
  }

  const billDate = bill.billDate ? new Date(bill.billDate) : new Date();
  const year = billDate.getFullYear();
  const query = BillSequence.findOneAndUpdate(
    { year },
    { $inc: { seq: 1 } },
    { new: true, upsert: true }
  );

  if (session) {
    query.session(session);
  }

  const sequenceDoc = await query;
  bill.billYear = year;
  bill.billSequence = sequenceDoc.seq;
  return { billYear: year, billSequence: sequenceDoc.seq };
};

const toMoney = (value) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
};

const computePaymentState = ({ payableAmount, paidAmount }) => {
  const payable = Math.max(toMoney(payableAmount), 0);
  const paid = Math.max(Math.min(toMoney(paidAmount), payable), 0);
  const remaining = Math.max(payable - paid, 0);

  let status = 'pending';
  if (payable <= 0 || paid >= payable) {
    status = 'paid';
  } else if (paid > 0) {
    status = 'partial';
  }

  return { paidAmount: paid, remainingAmount: remaining, paymentStatus: status };
};

const getPaidTotalFromPayments = (payments) => {
  return payments.reduce((total, payment) => {
    const status = String(payment.status || '').toLowerCase();
    if (status !== 'paid') {
      return total;
    }
    return total + toMoney(payment.amount);
  }, 0);
};

const syncBillFromPayments = async ({ bill, payments, session }) => {
  const safeSession = session && session.inTransaction() ? session : undefined;
  const billDoc = bill || null;
  if (!billDoc) {
    return null;
  }

  let paymentDocs = payments;
  if (!Array.isArray(paymentDocs)) {
    const query = Payment.find({ billId: billDoc._id }).sort({ createdAt: -1 });
    if (safeSession) {
      query.session(safeSession);
    }
    paymentDocs = await query;
  }

  const totalPaid = getPaidTotalFromPayments(paymentDocs);
  const nextState = computePaymentState({
    payableAmount: billDoc.payableAmount,
    paidAmount: totalPaid,
  });

  const { billYear, billSequence } = await ensureBillSequence({ bill: billDoc, session: safeSession }) || {};
  const nextBillCode = isInvalidBillCode(billDoc.billCode)
    ? formatBillCode(billYear || new Date().getFullYear(), billSequence || 1)
    : String(billDoc.billCode).trim();

  const hasChanged =
    billDoc.billCode !== nextBillCode ||
    Number(billDoc.paidAmount || 0) !== nextState.paidAmount ||
    Number(billDoc.remainingAmount || 0) !== nextState.remainingAmount ||
    String(billDoc.paymentStatus || 'pending') !== nextState.paymentStatus;

  if (hasChanged) {
    billDoc.billCode = nextBillCode;
    billDoc.paidAmount = nextState.paidAmount;
    billDoc.remainingAmount = nextState.remainingAmount;
    billDoc.paymentStatus = nextState.paymentStatus;
    await billDoc.save({ session: safeSession });
  }

  return billDoc;
};

module.exports = {
  formatBillCode,
  ensureBillSequence,
  computePaymentState,
  syncBillFromPayments,
};
