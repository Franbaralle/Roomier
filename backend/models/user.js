const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  username: { type: String, unique: true, required: true },
  password: { type: String, required: true },
  email: { type: String, required: false },
  birthdate: { type: Date, required: false },
  preferences: [{type: String}],
  personalInfo: {
    job: {type: String, required: false},
    religion: {type: String, required: false},
    politicPreference: {type: String, required: false},
    aboutMe: {type: String, required: false}
  },
  profilePhoto: { type: Buffer, required: false },
  verificationCode: { type: String, required: false },
  isVerified: { type: Boolean, default: false }
}); 

const User = mongoose.model('User', userSchema);

module.exports = User;