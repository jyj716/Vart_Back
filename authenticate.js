const Company = require('./schemas/company')
const passport = require('passport')

const admin = (req, res, next) => {
    verifyToken(req, res, next)

    if (req.user) {
        if (req.user.permission === 'admin') {
            next()
        } else {
            res.status(401).json({ message: "잘못된 권환" })
        }
    } else {
        res.status(401).json({ message: '로그인 하세요' })
    }
}

const user = (req, res, next) => {
    verifyToken(req, res, next)

    if (req.user) {
        next()
    } else {
        res.status(401).json({ message: '로그인 하세요' })
    }
}

const company = (req, res, next) => {
    verifyToken(req, res, next)

    if (req.user) {
        if (req.user.permission === 'company' | req.user.permission === 'admin') {
            next()
        } else {
            res.status(401).json({ message: "잘못된 권환" })
        }
    } else {
        res.status(401).json({ message: '로그인 하세요' })
    }
}

const signUp = (req, res, next) => {
    Company.findOne({ companyNum: req.body.companyNum }, (err, result) => {
        if (err) {
            console.log(err)
            res.status(500).json({ error: "서버 에러" })
        } else if (!result) {
            res.status(401).json({ message: "기업인이 아닙니다." })
        } else {
            next()
        }
    })
}

const verifyToken = (req, res, next) => {
    return passport.authenticate('jwt', { session: false }, (err, user) => {
        if (err) {
            console.log(err)
            return next(err)
        }
        if (!user) {
            return res.status(401).json({ message: 'The user does not exist.' })
        }

        req.user = user
    })(req, res, next)
}

module.exports = {
    admin,
    user,
    company,
    signUp
}