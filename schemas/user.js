const mongoose = require("mongoose");
const bcrypt = require('bcrypt')
const saltRounds = 10;
const { Schema } = mongoose;

const userSchema = new Schema({
  name: {
    type: String,
    required: true,
  },

  email: {
    type: String,
    trim: true,
    required: true,
  },

  password: {
    type: String,
    required: true,
  },

  businessnum: {
    type: Number
  },

  createdAt: {
    type: Date,
    default: Date.now(),
  },

  type: {
    type: String, // company, personal
  },

  permission: {
    type: String,
    default: "User"
  }
});

userSchema.pre('save', function (next) {     //save 하기 전에 Schema 
  let user = this
  if (user.isModified("password")) {
    bcrypt.genSalt(saltRounds, function (err, salt) {
      if (err) return next(err);
      bcrypt.hash(user.password, salt, function (err, hash) {
        if (err) return next(err);
        user.password = hash;
        next();
      });
    })
  } else {
    next();
  }
});

userSchema.pre('updateOne', function () {
  if (this._update.$set) {
    if (this._update.$set.password) {
      const hashedPassword = bcrypt.hashSync(this._update.$set.password, 10)
      this._update.$set.password = hashedPassword
    }
  }
})

userSchema.methods.comparePassword = function (inputPassword, cb) {
  const isValid = bcrypt.compareSync(inputPassword, this.password);

  if (isValid) {
    cb(null, true);
  } else {
    cb(null, false);
  }
};

module.exports = mongoose.model("User", userSchema);
