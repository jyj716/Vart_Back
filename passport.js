const passportJWT = require('passport-jwt');
const LocalStrategy = require('passport-local').Strategy
const JWTStrategy = passportJWT.Strategy;
const ExtractJWT = passportJWT.ExtractJwt;
const Users = require('./schemas/user')

const passportfnc = (passport) => {
    passport.serializeUser(function (user, done) {

        
        done(null, user);
    });

    passport.deserializeUser(function (user, done) {
        done(null, user);
    });

    passport.use('local', new LocalStrategy({
        usernameField: 'email',
        passwordField: 'password',
        session: true,
        passReqToCallback: false,
    }, (email, password, done) => {

        Users.findOne({ email }, (findError, user) => {
            if (findError) return done(findError); // 서버 에러 처리
            if (!user) return done(null, false, { message: '존재하지 않는 아이디입니다' }); // 임의 에러 처리

            return user.comparePassword(password, (passError, isMatch) => {
                if (isMatch) {
                    return done(null, user, null); // 검증 성공
                } else {
                    return done(null, false, { message: '비밀번호가 틀렸습니다' });
                }
            })
        }
        )
    }))

    passport.use('jwt', new JWTStrategy({ jwtFromRequest: ExtractJWT.fromAuthHeaderAsBearerToken(), secretOrKey: process.env.JWT_SECRET_KEY }, (jwtPayload, done) => {
        if (jwtPayload) {
            done(null, jwtPayload)
        } else {
            done(null, false, { message: "The token does not exist." })
        }
    }));
}

module.exports = passportfnc