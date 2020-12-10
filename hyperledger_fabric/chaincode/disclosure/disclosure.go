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

type Disclosure struct {
	No                       string `json:"no"`          // 번호
	ReportTitle              string `json:"reportTitle"` // 보고서 제목
	Date					 string `json:"date"`		 // 공시 작성일					
	Type   		             string `json:"type"`        // 유형
	ApplicableDate           string `json:"applicableDate"`  //적용 일자     
	Details 			     string `json:"details"`  	 //상세정보
	Token                	 string `json:"token"`       //토큰이름
}


func (s *Chaincode) Init(APIstub shim.ChaincodeStubInterface) sc.Response { 
	return shim.Success(nil)
}

func (s *Chaincode) Invoke(APIstub shim.ChaincodeStubInterface) sc.Response {
	function, args := APIstub.GetFunctionAndParameters() 
	if function == "readDisclosure" {
		return s.readDisclosure(APIstub, args)
	} else if function == "addDisclosure" {
		return s.addDisclosure(APIstub, args)
	} else if function == "readAllDisclosure" {
		return s.readAllDisclosure(APIstub)
	} else if function == "updateDisclosure" {
		return s.updateDisclosure(APIstub, args)
	}
	return shim.Error("Invalid Smart Contract function name.")
}


func (s *Chaincode) readDisclosure(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
	if len(args) != 1 { 
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}
	DisclosureAsBytes, _ := APIstub.GetState(args[0]) 
	return shim.Success(DisclosureAsBytes) 
}


func (s *Chaincode) addDisclosure(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
	if len(args) != 7 {
		return shim.Error("Incorrect number of arguments. Expecting 5")
	}
	var Disclosure = Disclosure{
	No:args[0],                      
	ReportTitle:args[1],          
	Date:args[2],					 									   	
	Type:args[3],   		           
	ApplicableDate:args[4],               
	Details:args[5], 		
	Token:args[6],
	}

	DisclosureAsBytes, _ := json.Marshal(Disclosure)
	APIstub.PutState(args[0], DisclosureAsBytes) 
	return shim.Success(nil)
}
	
func (s *Chaincode) readAllDisclosure(APIstub shim.ChaincodeStubInterface) sc.Response {
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
	
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}
	
		buffer.WriteString(string(queryResponse.Value))
		bArrayMemberAlreadyWritten = true
	}
	buffer.WriteString("]")

	fmt.Printf("- queryAllinfo:\n%s\n", buffer.String())

	return shim.Success(buffer.Bytes())
}
	
func (s *Chaincode) updateDisclosure(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {

	if len(args) != 7  {
		return shim.Error("Incorrect number of arguments. Expecting 2")
	}

	DisclosureAsBytes, _ := APIstub.GetState(args[0])
	if(DisclosureAsBytes == nil) {
		return shim.Error("This disclosure is not exist. Update fail")
	}

	Disclosures := Disclosure{}
	json.Unmarshal(DisclosureAsBytes, &Disclosures) 
	
	Disclosures = Disclosure{
	No:args[0],                      
	ReportTitle:args[1],          
	Date:args[2],					 							   	
	Type:args[3],   		           
	ApplicableDate:args[4],               
	Details:args[5], 
	Token:args[6],				
 }
	
 DisclosureAsBytes, _ = json.Marshal(Disclosures)
	APIstub.PutState(args[0], DisclosureAsBytes)

	return shim.Success(nil)
}


func main() { 


	err := shim.Start(new(Chaincode)) 
	if err != nil { 
		fmt.Printf("Error creating new Smart Contract: %s", err)
	}
}
