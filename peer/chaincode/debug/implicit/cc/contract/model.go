package contract

import (
	"encoding/json"
	"errors"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

var ErrNoIdData = errors.New("no id data")

type SmartContract struct {
	contractapi.Contract
}

type State struct {
	Id            string          `json:"id"`
	DataType      string          `json:"dataType"`
	Data          json.RawMessage `json:"data"`
	PrivateDataId string          `json:"pid"`
}

type StatePrivate struct {
	Id      string          `json:"id"`
	StateId string          `json:"stateId"`
	Data    json.RawMessage `json:"data"`
	Creator string          `json:"creator"`
}

type StateResp struct {
	Id            string            `json:"id"`
	DataType      string            `json:"dataType"`
	Data          string            `json:"data"`
	PrivateDataId string            `json:"pid"`
	PrivateData   *StatePrivateResp `json:"privateData"`
	Err           string            `json:"err"`
}

type StatePrivateResp struct {
	Id      string `json:"id"`
	StateId string `json:"stateId"`
	Data    string `json:"data"`
	Creator string `json:"creator"`
}

func (s *State) toResp() *StateResp {
	resp := &StateResp{
		Id:            s.Id,
		DataType:      s.DataType,
		Data:          string(s.Data),
		PrivateDataId: s.PrivateDataId,
	}
	return resp
}

func (sp *StatePrivate) toResp() *StatePrivateResp {
	resp := &StatePrivateResp{
		Id:      sp.Id,
		StateId: sp.StateId,
		Data:    string(sp.Data),
		Creator: sp.Creator,
	}
	return resp
}
