const mongoose = require("mongoose");
const { Schema } = mongoose;


const companySchema = new Schema({
    companyNum: {
        type: Number,
        required: true,
    }
});

module.exports = mongoose.model("Company", companySchema);
