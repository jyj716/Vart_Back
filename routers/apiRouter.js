const express = require("express");
const router = express.Router();

// 유저 정보
const userRouter = require("./userRouter");
// 공시 정보
const publicinfoRouter = require("./publicinfoRouter");
const disclosureRouter = require("./disclosureRouter")

router.use("/user", userRouter);
router.use("/publicinfo", publicinfoRouter);
router.use("/disclosure", disclosureRouter);

// 개발용(회사 숫자)
const Company = require("../schemas/company")

router.post('/companyNum', (req, res) => {
    const company = new Company(req.body);

    company.save((err) => {
        if (err) {
            console.log(err);
            res.status(500).send("Error sigup new user please try again");
        } else {
            res.status(200).send("Sign up is Success");
        }
    });
})

router.get("/find", (req, res) => {
    Company.findOne({ companyNum: req.body.companyNum }, (err, result) => {
        if (result) {
            res.json({ message: "일치" })
        } else {
            res.json({ message: "불일치" })
        }
    })
})

// 사진 저장
const multer = require('multer')
const fs = require('fs')

const storage = multer.diskStorage({
    destination: "./pubilc/img",
    filename: function (req, file, cb) {
        cb(null, `${Date.now()}.jpg`)
    }
})

const upload = multer({ storage })

router.post("/picture", upload.single('picture'), async (req, res) => {
    const fileBinary = await fs.readFileSync(req.file.path)

    await fs.unlinkSync(req.file.path)

    /*
        1. 바이너리 코드를 string으로 변환
        2. string으로 변환된 바이너리 코드를 byte로 변환
    */

    await fs.writeFileSync('./dog.jpg', fileBinary)
    res.json({ File: req.file, Binary: fileBinary })
})

module.exports = router;
