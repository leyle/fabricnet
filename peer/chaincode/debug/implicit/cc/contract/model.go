package contract

import (
	"encoding/json"
	"errors"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/leyle/go-api-starter/util"
)

var ErrNoIdData = errors.New("no id data")

type SmartContract struct {
	contractapi.Contract
}

type State struct {
	Id string `json:"id"`

	DataType string          `json:"dataType"`
	Data     json.RawMessage `json:"data"`

	PrivateDataId string `json:"pid"`

	CreateT *util.CurTime `json:"createT"`
	UpdateT *util.CurTime `json:"updateT"`
}

type StatePrivate struct {
	Id string `json:"id"`

	StateId string          `json:"stateId"`
	Data    json.RawMessage `json:"data"`
	Creator string          `json:"creator"`

	CreateT *util.CurTime `json:"createT"`
	UpdateT *util.CurTime `json:"updateT"`
}

type StateResp struct {
	Id string `json:"id"`

	DataType string `json:"dataType"`
	Data     string `json:"data"`

	PrivateDataId string            `json:"pid,omitempty"`
	PrivateData   *StatePrivateResp `json:"privateData,omitempty"`
	Err           string            `json:"err,omitempty"`

	CreateT *util.CurTime `json:"createT"`
	UpdateT *util.CurTime `json:"updateT"`
}

type StatePrivateResp struct {
	Id string `json:"id"`

	StateId string `json:"stateId"`
	Data    string `json:"data"`
	Creator string `json:"creator"`

	CreateT *util.CurTime `json:"createT"`
	UpdateT *util.CurTime `json:"updateT"`
}

func (s *State) toResp() *StateResp {
	resp := &StateResp{
		Id:            s.Id,
		DataType:      s.DataType,
		Data:          string(s.Data),
		PrivateDataId: s.PrivateDataId,
		CreateT:       s.CreateT,
		UpdateT:       s.UpdateT,
	}
	return resp
}

func (sp *StatePrivate) toResp() *StatePrivateResp {
	resp := &StatePrivateResp{
		Id:      sp.Id,
		StateId: sp.StateId,
		Data:    string(sp.Data),
		Creator: sp.Creator,
		CreateT: sp.CreateT,
		UpdateT: sp.UpdateT,
	}
	return resp
}
