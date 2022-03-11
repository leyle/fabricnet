package contract

import (
	"fmt"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	jsoniter "github.com/json-iterator/go"
	"github.com/leyle/go-api-starter/logmiddleware"
	"github.com/leyle/go-api-starter/util"
)

type CreateStateForm struct {
	StateId       string `json:"stateId"`
	DataType      string `json:"dataType"`
	Data          string `json:"data"`
	PrivateDataId string `json:"pid"`
}

func (s *SmartContract) CreateState(ctx contractapi.TransactionContextInterface, args string) error {
	var form CreateStateForm
	logger := logmiddleware.GetLogger(logmiddleware.LogTargetConsole)
	logger.Debug().Msg(args)

	err := jsoniter.UnmarshalFromString(args, &form)
	if err != nil {
		logger.Error().Str("args", args).Err(err)
		return err
	}

	dbForm := &State{
		Id:            form.StateId,
		DataType:      form.DataType,
		Data:          []byte(form.Data),
		PrivateDataId: form.PrivateDataId,
		CreateT:       util.GetCurTime(),
	}
	dbForm.UpdateT = dbForm.CreateT
	logger.Info().Str("id", dbForm.Id).Str("dataType", dbForm.DataType).Msg("create state")

	dbData, err := jsoniter.Marshal(dbForm)
	if err != nil {
		logger.Error().Str("args", args).Err(err)
		return err
	}

	err = ctx.GetStub().PutState(dbForm.Id, dbData)
	if err != nil {
		logger.Error().Str("id", dbForm.Id).Str("dataType", dbForm.DataType).Err(err)
		return err
	}
	return nil
}

func (s *SmartContract) GetStateById(ctx contractapi.TransactionContextInterface, id string) (*StateResp, error) {
	logger := logmiddleware.GetLogger(logmiddleware.LogTargetConsole)
	logger.Info().Str("method", "GetStateById").Str("id", id).Send()

	dbData, err := ctx.GetStub().GetState(id)
	if err != nil {
		logger.Error().Str("id", id).Err(err)
		return nil, err
	}

	if dbData == nil {
		logger.Warn().Str("id", id).Msg("no state data for the input id")
		return nil, ErrNoIdData
	}

	var state State
	err = jsoniter.Unmarshal(dbData, &state)
	if err != nil {
		logger.Error().Str("id", id).Err(err)
		return nil, err
	}

	stateResp := state.toResp()

	// try to get associated private data
	if state.PrivateDataId != "" {
		privateResp, err := s.GetStatePrivateById(ctx, state.PrivateDataId)
		if err != nil {
			stateResp.Err = fmt.Sprintf("get private data failed, %s", err.Error())
		}
		stateResp.PrivateData = privateResp
	}

	return stateResp, nil
}
