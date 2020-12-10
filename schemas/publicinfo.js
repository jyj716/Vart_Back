const mongoose = require('mongoose')


const company = new mongoose.Schema({
    id: {
        type: String,
        required: true
    },
    name: {
        type: String,
        required: true
    },
    establishmentDate: {
        type: String,
        required: true
    },

    location: {
        type: String,
        required: true
    },
    jurisdiction: {
        type: String,
        required: true
    },
    token: {
        name: {
            type: String,
            required: true
        },
        projectType: {
            type: String,
            required: true
        }
    },

    executive: {
        name: {
            type: String,
            required: true
        },
        education: {
            type: String,
            required: true
        },
        experience: {
            type: String,
            required: true
        }
    },
    developerleader: {
        name: {
            type: String,
            required: true
        },
        education: {
            type: String,
            required: true
        },
        experience: {
            type: String,
            required: true
        }
    }
})

module.exports = mongoose.model("companyinfo", company)