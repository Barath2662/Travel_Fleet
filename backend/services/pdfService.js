const fs = require('fs');
const path = require('path');
const PDFDocument = require('pdfkit');

const currency = (value) => Number(value || 0).toFixed(2);

const generateInvoicePdf = async (bill) => {
  const outputDir = path.join(__dirname, '..', 'uploads', 'invoices');
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const fileName = `invoice-${bill._id}.pdf`;
  const filePath = path.join(outputDir, fileName);

  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ margin: 36, size: 'A4' });
    const stream = fs.createWriteStream(filePath);

    doc.pipe(stream);

    const pageWidth = doc.page.width;
    const margin = doc.page.margins.left;
    const contentWidth = pageWidth - margin * 2;
    const formatDate = (value) => new Date(value).toLocaleDateString();

    const headerTop = margin;
    const rightBoxWidth = 190;
    const rightBoxHeight = 96;
    const rightBoxX = pageWidth - margin - rightBoxWidth;
    const leftX = margin;

    doc.font('Helvetica-Bold').fontSize(16).text('LOREM IPSUM TRAVELS', leftX, headerTop);
    doc.font('Helvetica').fontSize(9);
    doc.text('123 Lorem Street, Ipsum Nagar', leftX, headerTop + 20);
    doc.text('Dolor City, Sit 600001', leftX, headerTop + 32);
    doc.text('Tamil Nadu, India', leftX, headerTop + 44);
    doc.text('Phone: 90000 00000', leftX, headerTop + 58);
    doc.text('Email: lorem@ipsumtravels.com', leftX, headerTop + 70);

    doc.rect(rightBoxX, headerTop, rightBoxWidth, rightBoxHeight).stroke();
    doc.font('Helvetica-Bold').fontSize(11).text('CASH BILL / INVOICE', rightBoxX + 8, headerTop + 8, {
      width: rightBoxWidth - 16,
      align: 'center',
    });
    doc.font('Helvetica').fontSize(9);
    doc.text(`Invoice No: ${bill._id}`, rightBoxX + 8, headerTop + 30, {
      width: rightBoxWidth - 16,
    });
    doc.text(`Date: ${formatDate(bill.billDate)}`, rightBoxX + 8, headerTop + 44, {
      width: rightBoxWidth - 16,
    });
    doc.text(`Vehicle No: ${bill.vehicleNumber}`, rightBoxX + 8, headerTop + 58, {
      width: rightBoxWidth - 16,
    });
    doc.text(`Trip Date: ${formatDate(bill.tripDate)}`, rightBoxX + 8, headerTop + 72, {
      width: rightBoxWidth - 16,
    });

    const headerBottom = headerTop + rightBoxHeight + 14;
    doc.font('Helvetica-Bold').fontSize(11).text('Customer Name:', leftX, headerBottom);
    doc.font('Helvetica').fontSize(10).text(bill.customerName || 'Customer', leftX + 110, headerBottom);
    doc.font('Helvetica-Bold').fontSize(11).text('GSTIN:', leftX, headerBottom + 16);
    doc.font('Helvetica').fontSize(10).text('-', leftX + 110, headerBottom + 16);
    doc.font('Helvetica-Bold').fontSize(11).text('Route:', leftX, headerBottom + 32);
    doc.font('Helvetica').fontSize(10).text(bill.tripDetails || 'Pickup to Drop', leftX + 110, headerBottom + 32, {
      width: contentWidth - 110,
    });

    const tableTop = headerBottom + 56;
    const rowHeight = 22;
    const col1Width = Math.round(contentWidth * 0.68);
    const col2Width = contentWidth - col1Width;
    let rowY = tableTop;

    const drawRow = (label, value, options = {}) => {
      const isHeader = options.isHeader;
      const isSection = options.isSection;
      const isBold = options.isBold;
      if (isHeader || isSection) {
        doc.save();
        doc.rect(margin, rowY, contentWidth, rowHeight).fill(isHeader ? '#E5E7EB' : '#F3F4F6');
        doc.restore();
      }

      doc.rect(margin, rowY, contentWidth, rowHeight).stroke();
      doc.moveTo(margin + col1Width, rowY).lineTo(margin + col1Width, rowY + rowHeight).stroke();

      doc.font(isHeader || isSection || isBold ? 'Helvetica-Bold' : 'Helvetica').fontSize(10);
      doc.text(label, margin + 8, rowY + 6, { width: col1Width - 16 });
      doc.text(value, margin + col1Width + 8, rowY + 6, {
        width: col2Width - 16,
        align: 'right',
      });
      rowY += rowHeight;
    };

    drawRow('Details', 'Amount', { isHeader: true });
    drawRow('Time & KM Details', '', { isSection: true });
    drawRow('Start KM', `${bill.startKm}`);
    drawRow('End KM', `${bill.endKm}`);
    drawRow('Total KM', `${bill.totalKm}`);
    drawRow('Rate / KM', currency(bill.ratePerKm));
    drawRow('KM Charge', currency(bill.kmCharge));
    drawRow('Charges', '', { isSection: true });
    drawRow('Per Day', currency(bill.dayRent));
    drawRow('Per Hour', currency(bill.hourRent));
    drawRow('Driver Bata', currency(bill.driverBata));
    drawRow('Toll', currency(bill.tollCharges));
    drawRow('Permit / Other', currency((bill.permitCharges || 0) + (bill.parkingCharges || 0)));
    drawRow('TOTAL', currency(bill.totalAmount), { isBold: true });
    drawRow('PAYABLE', currency(bill.payableAmount), { isBold: true });

    const footerTop = rowY + 16;
    doc.font('Helvetica').fontSize(10).text('Amount in words: Rupees only.', leftX, footerTop);

    const footerLeftWidth = Math.round(contentWidth * 0.6);
    const footerRightX = leftX + footerLeftWidth + 12;
    const footerRightWidth = contentWidth - footerLeftWidth - 12;

    doc.font('Helvetica-Bold').fontSize(10).text('Bank Details', leftX, footerTop + 18);
    doc.font('Helvetica').fontSize(9);
    doc.text('Bank: Lorem Ipsum Bank', leftX, footerTop + 34);
    doc.text('A/C No: 1234567890', leftX, footerTop + 48);
    doc.text('IFSC: LORE0001234', leftX, footerTop + 62);
    doc.text('UPI: lorem@upi', leftX, footerTop + 76);

    const qrSize = 86;
    doc.rect(footerRightX, footerTop + 18, qrSize, qrSize).stroke();
    doc.font('Helvetica').fontSize(8).text('UPI QR', footerRightX, footerTop + 58, {
      width: qrSize,
      align: 'center',
    });

    const signBoxY = footerTop + 18;
    doc.rect(footerRightX + qrSize + 12, signBoxY, footerRightWidth - qrSize - 12, qrSize).stroke();
    doc.font('Helvetica').fontSize(8).text('Authorized Signatory', footerRightX + qrSize + 16, signBoxY + qrSize - 16, {
      width: footerRightWidth - qrSize - 24,
      align: 'center',
    });

    doc.end();

    stream.on('finish', () => {
      resolve({ filePath, relativePath: path.join('uploads', 'invoices', fileName) });
    });
    stream.on('error', reject);
  });
};

module.exports = { generateInvoicePdf };
