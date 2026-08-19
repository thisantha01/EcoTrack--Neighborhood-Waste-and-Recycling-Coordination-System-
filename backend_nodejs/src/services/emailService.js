const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',

  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

const sendVerificationOtp = async (
  email,
  name,
  otp
) => {
  const mailOptions = {
    from: `"Waste Management App" <${process.env.EMAIL_USER}>`,

    to: email,

    subject: 'Email Verification OTP',

    html: `
      <div style="
        font-family: Arial, sans-serif;
        max-width: 600px;
        margin: auto;
        padding: 20px;
        border: 1px solid #ddd;
        border-radius: 10px;
      ">

        <h2>Waste Management App</h2>

        <p>Hello ${name},</p>

        <p>
          Thank you for registering with our
          Waste Management Application.
        </p>

        <p>
          Your email verification OTP is:
        </p>

        <h1 style="
          letter-spacing: 8px;
          text-align: center;
        ">
          ${otp}
        </h1>

        <p>
          This OTP will expire in
          <strong>10 minutes</strong>.
        </p>

        <p>
          If you did not create this account,
          please ignore this email.
        </p>

        <p>
          Thank you,<br>
          Waste Management Team
        </p>

      </div>
    `,
  };

  await transporter.sendMail(mailOptions);
};

const sendPasswordResetOtp = async (
  email,
  name,
  otp
) => {
  const mailOptions = {
    from: `"Waste Management App" <${process.env.EMAIL_USER}>`,

    to: email,

    subject: 'Password Reset OTP',

    html: `
      <div style="
        font-family: Arial, sans-serif;
        max-width: 600px;
        margin: auto;
        padding: 20px;
      ">

        <h2>Password Reset</h2>

        <p>Hello ${name},</p>

        <p>
          We received a request to reset
          your password.
        </p>

        <p>Your password reset OTP is:</p>

        <h1 style="
          letter-spacing: 8px;
          text-align: center;
        ">
          ${otp}
        </h1>

        <p>
          This OTP will expire in
          <strong>10 minutes</strong>.
        </p>

        <p>
          If you did not request a password
          reset, please ignore this email.
        </p>

      </div>
    `,
  };

  await transporter.sendMail(mailOptions);
};

module.exports = {
  sendVerificationOtp,
  sendPasswordResetOtp,
};