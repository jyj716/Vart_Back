package main

/*
	shim library를 사용하겠다~~ >> DB(tx)에 access하고 체인코드를 호출하는 API를 제공
	여기서 hyperledger에서 peer와 헷갈리기 때문에 이름을 바꿔주기 위해 sc 명령어를 사용한다
*/
import (
	"bytes"
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric/core/chaincode/shim" 
  sc "github.com/hyperledger/fabric/protos/peer"  
)

// Define the Smart Contract structure
type Chaincode struct {
}

type Company struct {
	Id 								string `json:"id"`					// 고유번호
	Name 							string `json:"name"`				// 회사이름
	EstablishmentDate   			string `json:"establishmentdate"`   // 설립일
	Location          				string `json:"location"`            // 위치
	Jurisdiction 					string `json:"jurisdiction"`   // 법인관할자
	Token Token
	Executive Executive
	Developerleader Developerleader
}

// Define the car structure, cwith 4 properties.  Structure tags are used by encoding/json library
type Token struct {
	Name			string `json:"name"`           	// 토큰 이름
	ProjectType		string `json:"projecttype"`		// 프로젝트 종류
}

// 설립자
type Executive struct {
	Name      	string `json:"name"`		// 설립자 이름
	Education 	string `json:"education"`	// 설립자 학력
	Experience 	string `json:"experience"`	// 설립자 경력
}

// 개발자 리더
type Developerleader struct {
	Name      	string `json:"name"`                  // 개발자 리더 이름
	Education 	string `json:"education"`             // 개발자 리더 학력	
	Experience 	string `json:"experience"`            // 개발자 리더 경력
}

/**
	sc >> Import 된 peer와 CLI peer를 구분하기 위해 사용
	Init >> chaincode를 인스턴스화, 업그레이드 시킬때 자동으로 실행되는 함수 >> 생성자!!
	인자로 shim라이브러리의 ChaincodeStubInterface를 매개변수를 사용한다
	stub >> 블록체인에 들어있는 Ledger에 접근할때 사용하는 매개체
	rpc개념과 비슷!! (내 시스템 안에 있는 func을 호출하는게 아니라 다른 시스템 안에 있는 fuc을 호출할때는 Remote Procedure Call이라는 형태로 call한다!! 
	내가 call할 때 func을 호출하는 형태와 네트워크를 타고 목표하는 fuc을 호출하는 형태가 일관되게 유지해야한다!!
	but 네트워크를 타고갈때는 data형태로 이동을 한다!! 내 시스템안에서 func call을 하면 func 주소를 가지고 바로 호출하는데 네트워크를 타고 다른 시스템에 가게 되면
	그것을 Serialize를 통해 문자형태로 바꾸어서 네트워크 형태로 보내야 한다!!
	Stub >> 내 시스템에 내에 있는, or 다른 시스템 내에 있는 특정한 형태의 func을 연결해주는 매개체
	Shim에 있는 interface를 사용하는데 이름이 기니까 APIstub라는 이름으로 사용하겠다
	shim.ChaincodeStubInterface >> 원장에 대한 접근 수정을 위한 interface >> get, put과 같은 method가 내장.
*/
func (s *Chaincode) Init(APIstub shim.ChaincodeStubInterface) sc.Response { 
	return shim.Success(nil)
}
/*
	 Retrieve the requested Smart Contract function and arguments
	 stub.getFunc~ 메소드 >>peer가 chaincode를 인스턴스화 시키면서 Init을 수행시키면
	 web브라우저에서 user가 인자값을 넣고 function을 호출시켜 tx를 발생시켰을때 HyperLedger 블록체인에서 어떤게 호출되는 함수이고 어떤게 인자인지 구별하기 위해 사용!!


	 Route to the appropriate handler function to interact with the ledger appropriately
	 function이 querycar이냐?
	 querycar 함수에 인자를 넣으면서 호출한다 
*/	 
func (s *Chaincode) Invoke(APIstub shim.ChaincodeStubInterface) sc.Response {
	function, args := APIstub.GetFunctionAndParameters() 
	if function == "readPublicinfo" {
		return s.readPublicinfo(APIstub, args)
	} else if function == "addPublicinfo" {
		return s.addPublicinfo(APIstub, args)
	} else if function == "readAllPublicinfo" {
		return s.readAllPublicinfo(APIstub)
	} else if function == "updatePublicinfo" {
		return s.updatePublicinfo(APIstub, args)
	}
	return shim.Error("Invalid Smart Contract function name.")
}

/*  UqueryCar가 interface를 사용하게따
	queryCar을 하려면 어떤 car인지 인자가 필요하다!!
	sc.Response >> sc : peer 라이브러리 내에서 Response를 쓰는데 Response 내에서는 반환하는 값들이 저장되어있다
	인자의 길이가 0이면 에러를 발생시킨다
	GetState >> stateDB에서 인자값에 해당하는 내용을 가져온다 >> 만약 원장에 commit 되지 않은 writeset 데이터는 읽지 않는다
	_ >> carAsBytes를 반환할수 없으면 에러를 반환한다
	shim 라이브러리 내 Success 함수 >> stateDB에 잘 update가 되었다~ >> 성공상태 정보, 바이트 형태의 페이로드 데이터(user가 누군지, car는 어떤 차인지)를 반환 >> 여기서는 carAsBytes를 반환
	PutState가 발생되면 transaction이 일어나게 된다 >> 지정된 key와 value를 트랜잭션의 writeset에 data-write proposal 수행(일단 tx를 endorsor peer한테까지만 전달된 초기상태인 상황이다!!) >> 데이터 추가에 대한 요청(proposal)들만 수행 >> proposal들이 모여서 일정시간 검증되면 새로운 block이 생성된다 >> 또 다른 과정!!
*/	
func (s *Chaincode) readPublicinfo(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
	if len(args) != 1 { 
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}
	companyAsBytes, _ := APIstub.GetState(args[0]) 
	return shim.Success(companyAsBytes) 
}


func (s *Chaincode) addPublicinfo(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
	if len(args) != 13 {
		return shim.Error("Incorrect number of arguments. Expecting 5")
	}
	var Company = Company{
		Id : args[0],
		Name : args[1],
		EstablishmentDate : args[2],
		Location : args[3], 
		Jurisdiction : args[4],
		Token : Token{	
			Name:args[5],
			ProjectType:args[6]},
		Executive: Executive{
			Name:args[7],      	
			Education:args[8],
			Experience:args[9]},
		Developerleader : Developerleader{
			Name:args[10],      	
			Education:args[11],
			Experience:args[12]}}

	companyAsBytes, _ := json.Marshal(Company)
	APIstub.PutState(args[0], companyAsBytes) 
	return shim.Success(nil)
}
	//GetStateByRange >> 원장에서 data를 읽어올때 더미로 읽어들이고 싶을때
	//finally 블럭처럼 마지막에 Clean-up 작업을 하기 위해 사용
	// buffer is a JSON array containing QueryResults
func (s *Chaincode) readAllPublicinfo(APIstub shim.ChaincodeStubInterface) sc.Response {
	startKey := ""
	endKey   := ""

	resultsIterator, err := APIstub.GetStateByRange(startKey, endKey)
	
	if err != nil {
		return shim.Error(err.Error())
	}
	defer resultsIterator.Close() 

	
	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return shim.Error(err.Error())
		}
		// Add a comma before array members, suppress it for the first array member
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}
		// Record is a JSON object, so we write as-is
		buffer.WriteString(string(queryResponse.Value))
		bArrayMemberAlreadyWritten = true
	}
	buffer.WriteString("]")

	fmt.Printf("- queryAllinfo:\n%s\n", buffer.String())

	return shim.Success(buffer.Bytes())
}
	/* 전달받은 carAsBytes라는 JSON 형식의 데이터를 car 구조체 안의 값으로 집어넣음
	 인자인 key값(args[0])에 대한 stateDB 내의 date를 보여준다
    */
func (s *Chaincode) updatePublicinfo(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {

	if len(args) != 13 {
		return shim.Error("Incorrect number of arguments. Expecting 2")
	}

	companyAsBytes, _ := APIstub.GetState(args[0])
	if(companyAsBytes == nil) {
		return shim.Error("This vart is not exist. Update fail")
	}
	Companys := Company{}
	json.Unmarshal(companyAsBytes, &Companys) 
	
	Companys = Company{
		Id : args[0],
		Name : args[1],
		EstablishmentDate : args[2],
		Location : args[3], 
		Jurisdiction : args[4],
		Token : Token{	
			Name:args[5],
			ProjectType:args[6]},
		Executive: Executive{
			Name:args[7],      	
			Education:args[8],
			Experience:args[9]},
		Developerleader : Developerleader{
			Name:args[10],      	
			Education:args[11],
			Experience:args[12]}}
	
	companyAsBytes, _ = json.Marshal(Companys)
	APIstub.PutState(args[0], companyAsBytes)

	return shim.Success(nil)
}

/*
    The main tion is only relevant in unit test mode. Only included here for completeness.
	Create a new Smart Contract
	shim.start >> 스마트 컨트랙트 생성
	스마트 컨트랙트를 발생시켰을때 에러가 발생되었으면 출력하겠다
*/	
func main() { 


	err := shim.Start(new(Chaincode)) 
	if err != nil { 
		fmt.Printf("Error creating new Smart Contract: %s", err)
	}
}
