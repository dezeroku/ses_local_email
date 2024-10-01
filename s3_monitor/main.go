package main

import (
	"context"
	"encoding/json"
	"log"
	"os"
	"path"
	"time"

	"github.com/aws/aws-sdk-go-v2/config"

	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
)

var (
	queueUrlEnvVar          = "QUEUE_URL"
	bucketNameEnvVar        = "BUCKET_NAME"
	storagePathEnvVar       = "STORAGE_PATH"
	idleSleepDurationEnvVar = "IDLE_SLEEP_DURATION"

	addedObjectSuffix = ".eml"
)

func requireEnvVariable(name string) string {
	value, present := os.LookupEnv(name)
	if !present {
		log.Fatalf("Env variable %s is required, but not present", name)
	}
	return value
}

func main() {
	queueUrl := requireEnvVariable(queueUrlEnvVar)
	bucketName := requireEnvVariable(bucketNameEnvVar)

	storagePathVar := requireEnvVariable(storagePathEnvVar)
	storagePath := path.Clean(storagePathVar)

	os.MkdirAll(storagePath, os.ModePerm)

	var idleSleepDuration time.Duration
	idleSleepDurationVar, present := os.LookupEnv(idleSleepDurationEnvVar)
	if !present {
		idleSleepDuration = 300 * time.Second
	} else {
		var err error
		idleSleepDuration, err = time.ParseDuration(idleSleepDurationVar)
		if err != nil {
			log.Fatal(err)
		}
	}

	log.Printf("idleSleepDuration set to %v", idleSleepDuration)

	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		log.Fatal(err)
	}

	s3Client := s3.NewFromConfig(cfg)
	sqsClient := sqs.NewFromConfig(cfg)

	for {
		msgResult, err := ReceiveMessage(sqsClient, queueUrl, 20)
		if err != nil {
			log.Fatal(err)
		}

		for _, message := range msgResult.Messages {
			receiptHandle := *message.ReceiptHandle
			log.Printf("New event received: %s", receiptHandle)

			body := *message.Body
			var event ObjectCreatedEvent
			if err := json.Unmarshal([]byte(body), &event); err != nil {
				log.Fatal(err)
			}

			objectKey := event.Detail.Object.Key
			fileName := objectKey + addedObjectSuffix

			if err := DownloadFile(s3Client, bucketName, objectKey, path.Join(storagePath, fileName)); err != nil {
				log.Fatal(err)
			}

			if err := DeleteFile(s3Client, bucketName, objectKey); err != nil {
				log.Fatal(err)
			}

			if err := DeleteMessage(sqsClient, queueUrl, receiptHandle); err != nil {
				log.Fatal(err)
			}
		}

		if len(msgResult.Messages) == 0 {
			log.Printf("Idle sleeping for %v", idleSleepDuration)
			time.Sleep(idleSleepDuration)
		}
	}
}
