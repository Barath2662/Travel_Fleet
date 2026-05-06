const toNumber = (value, fallback = 0) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const computeBillFields = (payload) => {
  const startKm = toNumber(payload.startKm);
  const endKm = toNumber(payload.endKm);
  const totalKm = Math.max(endKm - startKm, 0);
  const kmCharge = totalKm * toNumber(payload.ratePerKm);

  const totalAmount =
    toNumber(payload.baseFare) +
    toNumber(payload.driverBata) +
    toNumber(payload.tollCharges) +
    toNumber(payload.permitCharges) +
    toNumber(payload.waitingCharges) +
    toNumber(payload.extraCharges) +
    toNumber(payload.fastagCharges);

  const gstPercent = Math.max(toNumber(payload.gstPercent), 0);
  const gstAmount = totalAmount * (gstPercent / 100);
  const advanceReceived = Math.max(toNumber(payload.advanceReceived), 0);
  const finalAmount = totalAmount + gstAmount - advanceReceived;

  const distance = totalKm;

  return {
    totalKm,
    kmCharge,
    totalAmount,
    gstPercent,
    gstAmount,
    finalAmount,
    payableAmount: Math.max(finalAmount, 0),
    distance,
  };
};

module.exports = { toNumber, computeBillFields };
