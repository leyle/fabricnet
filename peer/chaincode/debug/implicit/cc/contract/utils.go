package contract

import (
	"fmt"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"strings"
)

func GetClientMSPID(ctx contractapi.TransactionContextInterface) (string, error) {
	mspID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		err = fmt.Errorf("get submitter's mspid failed, %s", err.Error())
		fmt.Println(err.Error())
		return "", err
	}
	return mspID, nil
}

func generateCollectionName(mspId string, shared bool) string {
	// format
	// self name is: mspid + noshare
	// shared name is: mspid + sharewrite
	name := strings.ToLower(mspId)
	suffix := "noshare"
	if shared {
		suffix = "sharewrite"
	}
	return fmt.Sprintf("%s%s", name, suffix)
}
