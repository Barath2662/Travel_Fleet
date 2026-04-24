const Bill = require('../models/Bill');
const Payment = require('../models/Payment');

const buildBillCodeFromId = (id) => `BILL-${String(id).toUpperCase()}`;

const isInvalidBillCode = (billCode) => {
  const value = String(billCode || '').trim();
  return !value || value === 'BILL-NA';
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
  if (paid >= payable && payable > 0) {
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

  const nextBillCode = isInvalidBillCode(billDoc.billCode)
    ? buildBillCodeFromId(billDoc._id)
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
  buildBillCodeFromId,
  computePaymentState,
  syncBillFromPayments,
};
