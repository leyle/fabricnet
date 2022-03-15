package contract

import (
	"fmt"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
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

func generateCollectionName(mspid string) string {
	// format is: _implicit_org_MSPID
	const prefix = "_implicit_org_"
	return fmt.Sprintf("%s%s", prefix, mspid)
}
