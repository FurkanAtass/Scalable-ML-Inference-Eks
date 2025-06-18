#! /bin/bash

if [ "$1" == "dev" ]; then
    uvicorn main:app --reload
else
    uvicorn main:app
fi