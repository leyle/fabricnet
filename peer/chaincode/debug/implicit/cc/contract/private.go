package contract

import (
	"fmt"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	jsoniter "github.com/json-iterator/go"
	"github.com/leyle/go-api-starter/logmiddleware"
	"github.com/leyle/go-api-starter/util"
)

type CreateStatePrivateForm struct {
	StateId string   `json:"stateId"`
	Data    string   `json:"data"`
	Targets []string `json:"targets"`
}

func (sp *SmartContract) CreateStatePrivate(ctx contractapi.TransactionContextInterface, transientKey string) (string, error) {
	logger := logmiddleware.GetLogger(logmiddleware.LogTargetStdout)
	tMap, err := ctx.GetStub().GetTransient()
	if err != nil {
		logger.Error().Str("transientKey", transientKey).Err(err)
		return "", err
	}

	// get raw private data
	form, ok := tMap[transientKey]
	if !ok {
		err = fmt.Errorf("get private data from transientKey[%s] failed", transientKey)
		logger.Error().Err(err)
		return "", err
	}

	// unmarshal private data
	var statePrivateForm CreateStatePrivateForm
	err = jsoniter.Unmarshal(form, &statePrivateForm)
	if err != nil {
		logger.Error().Msgf("unmarshal input data failed, %v", err)
		return "", err
	}

	// generate db form
	id := util.GenerateDataId()
	creator, err := GetClientMSPID(ctx)
	if err != nil {
		logger.Error().Err(err)
		return "", nil
	}

	dbForm := &StatePrivate{
		Id:      id,
		StateId: statePrivateForm.StateId,
		Data:    []byte(statePrivateForm.Data),
		Creator: creator,
		CreateT: util.GetCurTime(),
	}
	dbForm.UpdateT = dbForm.CreateT
	dbData, _ := jsoniter.Marshal(dbForm)

	// write to many targets
	// target collection name format is: _implicit_org_MSPID
	// firstly, write data to target collections, then write to itself collection
	for _, mspid := range statePrivateForm.Targets {
		collectionName := generateCollectionName(mspid)
		logger.Info().Str("collectionName", collectionName).Str("stateId", dbForm.StateId).Str("id", dbForm.Id).Msg("current writing private data")
		err = savePrivateState(ctx, collectionName, dbForm.Id, dbData)
		if err != nil {
			logger.Error().Str("collectionName", collectionName).Str("stateId", dbForm.StateId).Str("id", dbForm.Id).Err(err)
			return "", err
		}
	}

	return dbForm.Id, nil
}

func savePrivateState(ctx contractapi.TransactionContextInterface, collectionName, id string, data []byte) error {
	err := ctx.GetStub().PutPrivateData(collectionName, id, data)
	if err != nil {
		fmt.Printf("put private data failed, collectionName[%s], id[%s], err:%v\n", collectionName, id, err)
		return err
	}
	return nil
}

func (sp *SmartContract) GetStatePrivateById(ctx contractapi.TransactionContextInterface, id string) (*StatePrivateResp, error) {
	logger := logmiddleware.GetLogger(logmiddleware.LogTargetConsole)
	logger.Info().Str("method", "GetStatePrivateById").Str("id", id).Send()
	mspid, err := GetClientMSPID(ctx)
	if err != nil {
		logger.Error().Str("id", id).Msgf("get client mspid failed, %v", err)
		return nil, err
	}

	collectionName := generateCollectionName(mspid)
	dbData, err := ctx.GetStub().GetPrivateData(collectionName, id)
	if err != nil {
		logger.Error().Str("id", id).Msgf("get private data failed, %v", err)
		return nil, err
	}

	if dbData == nil {
		logger.Warn().Str("id", id).Msg("get private data, but no data")
		return nil, ErrNoIdData
	}

	var statePrivate StatePrivate
	err = jsoniter.Unmarshal(dbData, &statePrivate)
	if err != nil {
		logger.Error().Str("id", id).Err(err)
		return nil, err
	}

	return statePrivate.toResp(), nil
}

func GetStatePrivateByStateId() {

}
