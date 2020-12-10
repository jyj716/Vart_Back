const router = require("express").Router();
const publicinfotx = require('./publicinfotx')
const authenticate = require('../authenticate')
const utils = require("./utils")

//조회
router.get("/query/:id", async (req, res) => {
  console.log('프로필 조회')
  let data = {
    contract: await utils.wallet('vart'),
    id: req.params.id,
  };

  let result = await publicinfotx.readPublicinfo(data);

  if (!result.result) {
    console.log(`Error : ${result.data}`)
    res.status(500).json(JSON.parse(result.data))
  } else if (result.data === undefined) {
    res.status(401).json({ message: "해당 프로필이 없습니다." });
  } else {
    const show = result.data.toString('utf-8') // string(JSON)
    const realresult = JSON.parse(show) // object

    res.json(realresult);
  }
});

//전체 조회
router.get("/list", async (req, res) => {
  console.log('프로필 전체 조회')

  var data = {
    contract: await utils.wallet('vart')
  };

  let result = await publicinfotx.readAllPublicinfo(data); // buffer
  console.log(result)
  if (result.result) {
    const show = result.data.toString('utf-8') // string(JSON)
    const realresult = JSON.parse(show) // object

    const projection = {
      Developerleader: 0,
      Executive: 0
    }

    for (let info of realresult) {
      await utils.selectProperties(info, projection)
    }

    res.json(realresult);

  } else {
    console.log(`Error : ${result.data}`)
    res.status(401).json(JSON.parse(result.data))
  }
});

//공시 정보 입력(코인 이름, 코인 가격, 상장 여부 등등)
router.post("/invoke", authenticate.company, async (req, res) => {
  console.log("프로필 정보 입력")

  // req.body.company.id = `${Date.now()}_${req.body.company.token.name}`

  // const request = {
  //   contract: await utils.wallet('vart'),
  //   company: req.body.company
  // }
  console.log(req.token)
  const company = {
    ...req.body,
    id: `${Date.now()}_${req.body.token.name}`
  }
  const request = {
    contract: await utils.wallet('vart'),
    company: company
  }


  const result = await publicinfotx.addPublicinfo(request);
  if (result) {
    res.status(200).json({ message: 'Success' })
  } else {
    res.status(401).json({ error: "Failed to submit transaction" })
  }
})

//공시 정보 업데이트
router.post("/update", authenticate.company, async (req, res) => {
  console.log("프로필 정보 업데이트")

  const request = {
    contract: await utils.wallet('vart'),
    company: req.body.company
  }

  const result = await publicinfotx.updatePublicinfo(request);

  if (result) {
    res.status(200).send('성공')
  } else {
    console.log(reulst)
    res.status(401).json(JSON.parse(result))
  }
});

module.exports = router;


