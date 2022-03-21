package main

import (
	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/leyle/go-api-starter/logmiddleware"
	"implicitcc/contract"
	"io/ioutil"
	"log"
	"os"
	"strconv"
)

func main() {
	logger := logmiddleware.GetLogger(logmiddleware.LogTargetConsole)

	ccid := os.Getenv("CHAINCODE_ID")
	addr := os.Getenv("CHAINCODE_SERVER_ADDRESS")

	if ccid == "" || addr == "" {
		logger.Error().Msg("No chaincode ccid or listening address")
		os.Exit(1)
	}
	logger.Info().Str("CHAINCODE_ID", ccid).Send()
	logger.Info().Str("CHAINCODE_SERVER_ADDRESS", addr).Send()

	cc, err := contractapi.NewChaincode(&contract.SmartContract{})
	if err != nil {
		logger.Error().Msgf("new chaincode failed, %v", err)
		os.Exit(1)
	}

	server := &shim.ChaincodeServer{
		CCID:     ccid,
		Address:  addr,
		CC:       cc,
		TLSProps: getTLSProperties(),
	}
	logger.Info().Msg("trying to start chaincode server...")
	err = server.Start()
	if err != nil {
		logger.Error().Msgf("start chaincode server failed, %v", err)
		os.Exit(1)
	}
}

// below copy from somewhere else.
func getTLSProperties() shim.TLSProperties {
	// Check if chaincode is TLS enabled
	tlsDisabledStr := getEnvOrDefault("CHAINCODE_TLS_DISABLED", "true")
	key := getEnvOrDefault("CHAINCODE_TLS_KEY", "")
	cert := getEnvOrDefault("CHAINCODE_TLS_CERT", "")
	clientCACert := getEnvOrDefault("CHAINCODE_CLIENT_CA_CERT", "")

	// convert tlsDisabledStr to boolean
	tlsDisabled := getBoolOrDefault(tlsDisabledStr, false)
	var keyBytes, certBytes, clientCACertBytes []byte
	var err error

	if !tlsDisabled {
		keyBytes, err = ioutil.ReadFile(key)
		if err != nil {
			log.Panicf("error while reading the crypto file: %s", err)
		}
		certBytes, err = ioutil.ReadFile(cert)
		if err != nil {
			log.Panicf("error while reading the crypto file: %s", err)
		}
	}
	// Did not request for the peer cert verification
	if clientCACert != "" {
		clientCACertBytes, err = ioutil.ReadFile(clientCACert)
		if err != nil {
			log.Panicf("error while reading the crypto file: %s", err)
		}
	}

	return shim.TLSProperties{
		Disabled:      tlsDisabled,
		Key:           keyBytes,
		Cert:          certBytes,
		ClientCACerts: clientCACertBytes,
	}
}

func getEnvOrDefault(env, defaultVal string) string {
	value, ok := os.LookupEnv(env)
	if !ok {
		value = defaultVal
	}
	return value
}

// Note that the method returns default value if the string
// cannot be parsed!
func getBoolOrDefault(value string, defaultVal bool) bool {
	parsed, err := strconv.ParseBool(value)
	if err != nil {
		return defaultVal
	}
	return parsed
}
