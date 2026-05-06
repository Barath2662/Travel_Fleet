const toNumber = (value, fallback = 0) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const computeBillFields = (payload) => {
  const startKm = toNumber(payload.startKm);
  const endKm = toNumber(payload.endKm);
  const totalKm = Math.max(toNumber(payload.totalKm) || endKm - startKm, 0);
  const ratePerKm = Math.max(toNumber(payload.ratePerKm), 0);
  const kmCharge = totalKm * ratePerKm;

  const totalDays = Math.max(toNumber(payload.numberOfDays || payload.totalDays), 0);
  const dayRent = Math.max(toNumber(payload.dayRent), 0);
  const dayCharge = totalDays * dayRent;

  const totalHours = Math.max(toNumber(payload.totalHours || payload.numberOfHours), 0);
  const hourRent = Math.max(toNumber(payload.hourRent), 0);
  const hourCharge = totalHours * hourRent;

  const baseFare = Math.max(toNumber(payload.baseFare), 0);
  const includeBaseFare = baseFare > 0 && kmCharge + dayCharge + hourCharge <= 0;

  const totalAmount =
    (includeBaseFare ? baseFare : 0) +
    kmCharge +
    dayCharge +
    hourCharge +
    toNumber(payload.tollCharges) +
    toNumber(payload.permitCharges) +
    toNumber(payload.parkingCharges) +
    toNumber(payload.driverBata) +
    toNumber(payload.waitingCharges) +
    toNumber(payload.extraCharges) +
    toNumber(payload.fastagCharges);

  const gstPercent = Math.max(toNumber(payload.gstPercent), 0);
  const gstAmount = totalAmount * (gstPercent / 100);
  const advanceReceived = Math.max(toNumber(payload.advanceReceived), 0);
  const finalAmount = totalAmount + gstAmount - advanceReceived;

  return {
    totalKm,
    ratePerKm,
    kmCharge,
    totalDays,
    dayCharge,
    totalHours,
    hourCharge,
    totalAmount,
    gstPercent,
    gstAmount,
    finalAmount,
    payableAmount: Math.max(finalAmount, 0),
    distance: totalKm,
  };
};

module.exports = { toNumber, computeBillFields };
