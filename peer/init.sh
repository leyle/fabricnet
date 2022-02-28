#!/bin/bash

GLOBAL_ENV=../global.env
LOCAL_ENV=./local.env
USER_ENV=./user.env

ORG_ENV=../sharedvolume/env.org

/usr/bin/env python mergeEnv.py --global_env $GLOBAL_ENV --local_env $LOCAL_ENV --user_env $USER_ENV --org_env $ORG_ENV
