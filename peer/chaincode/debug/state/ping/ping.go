package main

import (
	"flag"
	"fmt"
	jsoniter "github.com/json-iterator/go"
	"github.com/leyle/go-api-starter/util"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"time"

	"github.com/hyperledger/fabric-sdk-go/pkg/core/config"
	"github.com/hyperledger/fabric-sdk-go/pkg/gateway"
)

const (
	username      = "orgadmin"
	_adminMSPPath = "../../../../../users/orgadmin/msp"
	_ccFile       = "../../../../connection.yaml"
	_chName       = "fabricapp"
	_ccName       = "state"
)

const dataType = "emalidevtest"
const postData = "{\"company\":\"emali.io\",\"programmer\":\"zls\",\"age\":99,\"purpose\":\"test chaincode\"}"
const orgName = "emalidev"

const funcCreateState = "CreateState"

var (
	chName       string
	ccName       string
	mspId        string
	adminMSPPath string
	ccFile       string
)

type CurT struct {
	T      int64  `json:"t"`
	HumanT string `json:"humanT"`
}

type CreateForm struct {
	Id          string   `json:"id"`
	DataId      string   `json:"dataId"`
	Data        string   `json:"data"`
	DataType    string   `json:"dataType"`
	PrivateInfo []string `json:"privateInfo"`
	ShareList   []string `json:"shareList"`
	OrgName     string   `json:"orgName"`
	CreateTime  *CurT    `json:"createTime"`
	UpdateTime  *CurT    `json:"updateTime"`
}

func getCurT() *CurT {
	t := time.Now()
	curT := &CurT{
		T:      t.Unix(),
		HumanT: t.Format("2006-01-02 15:04:05"),
	}
	return curT
}

func getCreateForm(id string) string {
	form := &CreateForm{
		Id:         id,
		DataId:     id + "dataId",
		Data:       postData,
		DataType:   dataType,
		OrgName:    orgName,
		CreateTime: getCurT(),
	}
	form.UpdateTime = form.CreateTime
	fmt.Printf("getCreateForm, id[%s], time[%s]\n", form.Id, form.CreateTime.HumanT)

	data, _ := jsoniter.MarshalToString(&form)
	return data
}

func main() {
	// essential args
	flag.StringVar(&chName, "ch", _chName, "-ch fabricapp")
	flag.StringVar(&ccName, "cc", _ccName, "-cc state")
	flag.StringVar(&mspId, "mspid", "", "-mspid org1MSP")

	// optional args
	flag.StringVar(&adminMSPPath, "admin", _adminMSPPath, "-admin /some/path/to/admin/msp")
	flag.StringVar(&ccFile, "ccfile", _ccFile, "-ccfile /some/path/to/connection.yaml")

	flag.Parse()

	fmt.Println("chName:", chName)
	fmt.Println("ccName:", ccName)
	fmt.Println("mspId:", mspId)
	fmt.Println("adminMSPPath:", adminMSPPath)
	fmt.Println("ccFile:", ccFile)

	if chName == "" || ccName == "" || mspId == "" {
		fmt.Println("usage: ./state-ping -h")
		os.Exit(1)
	}

	log.Println("============ application-golang starts ============")

	err := os.Setenv("DISCOVERY_AS_LOCALHOST", "false")
	if err != nil {
		log.Fatalf("Error setting DISCOVERY_AS_LOCALHOST environemnt variable: %v", err)
	}

	wallet, err := gateway.NewFileSystemWallet("wallet")
	if err != nil {
		log.Fatalf("Failed to create wallet: %v", err)
	}

	if !wallet.Exists(username) {
		err = populateWallet(wallet)
		if err != nil {
			log.Fatalf("Failed to populate wallet contents: %v", err)
		}
	}

	ccpPath := ccFile

	gw, err := gateway.Connect(
		gateway.WithConfig(config.FromFile(filepath.Clean(ccpPath))),
		gateway.WithIdentity(wallet, username),
	)
	if err != nil {
		log.Fatalf("Failed to connect to gateway: %v", err)
	}
	defer gw.Close()

	network, err := gw.GetNetwork(chName)
	if err != nil {
		log.Fatalf("Failed to get network: %v", err)
	}

	contract := network.GetContract(ccName)

	log.Println("--> Evaluate Transaction: Ping, function returns client info on the ledger")
	result, err := contract.EvaluateTransaction("Ping")
	if err != nil {
		log.Fatalf("Failed to evaluate transaction: %v", err)
	}
	log.Println(string(result))

	log.Println("--> Submit Transaction: CreateState")
	formId := util.GenerateDataId()
	stateArgs := getCreateForm(formId)
	_, err = contract.SubmitTransaction(funcCreateState, stateArgs)
	if err != nil {
		log.Fatalf("Failed to submit transaction: %v", err)
	}

	// get back this data by GetStateById()
	log.Println("--> Evaluate Transaction: GetStateById")
	result, err = contract.EvaluateTransaction("GetStateById", formId)
	if err != nil {
		log.Fatalf("Failed to evaluate transaction: %v", err)
	}
	log.Println(string(result))

	log.Println("============ application-golang ends ============")
}

func populateWallet(wallet *gateway.Wallet) error {
	log.Println("============ Populating wallet ============")
	credPath := adminMSPPath

	certPath := filepath.Join(credPath, "signcerts", "cert.pem")
	// read the certificate pem
	cert, err := ioutil.ReadFile(filepath.Clean(certPath))
	if err != nil {
		return err
	}

	keyDir := filepath.Join(credPath, "keystore")
	// there's a single file in this dir containing the private key
	files, err := ioutil.ReadDir(keyDir)
	if err != nil {
		return err
	}
	if len(files) != 1 {
		return fmt.Errorf("keystore folder should have contain one file")
	}
	keyPath := filepath.Join(keyDir, files[0].Name())
	key, err := ioutil.ReadFile(filepath.Clean(keyPath))
	if err != nil {
		return err
	}

	identity := gateway.NewX509Identity(mspId, string(cert), string(key))

	return wallet.Put(username, identity)
}
