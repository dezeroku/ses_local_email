package main

import (
	"context"
	"io"
	"log"
	"os"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
)

func DownloadFile(s3Client *s3.Client, bucketName string, objectKey string, fileName string) error {
	log.Printf("Downloading object %v:%v as %v", bucketName, objectKey, fileName)
	result, err := s3Client.GetObject(context.TODO(), &s3.GetObjectInput{
		Bucket: aws.String(bucketName),
		Key:    aws.String(objectKey),
	})
	if err != nil {
		return err
	}
	defer result.Body.Close()
	file, err := os.Create(fileName)
	if err != nil {
		return err
	}
	defer file.Close()
	body, err := io.ReadAll(result.Body)
	if err != nil {
		return err
	}
	_, err = file.Write(body)
	return err
}

func DeleteFile(s3Client *s3.Client, bucketName string, objectKey string) error {
	log.Printf("Deleting object %v:%v", bucketName, objectKey)
	_, err := s3Client.DeleteObject(context.TODO(), &s3.DeleteObjectInput{
		Bucket: aws.String(bucketName),
		Key:    aws.String(objectKey),
	})

	return err
}

func DeleteMessage(sqsClient *sqs.Client, queueUrl string, receiptHandle string) error {
	log.Printf("Deleting message %v from queue %v", receiptHandle, queueUrl)
	_, err := sqsClient.DeleteMessage(context.TODO(), &sqs.DeleteMessageInput{
		QueueUrl:      aws.String(queueUrl),
		ReceiptHandle: aws.String(receiptHandle),
	})

	return err
}

func ReceiveMessage(sqsClient *sqs.Client, queueUrl string, waitTimeSeconds int32) (*sqs.ReceiveMessageOutput, error) {
	log.Printf("Polling messages from queue %v", queueUrl)
	msgResult, err := sqsClient.ReceiveMessage(context.TODO(), &sqs.ReceiveMessageInput{
		QueueUrl:        aws.String(queueUrl),
		WaitTimeSeconds: waitTimeSeconds,
	})

	return msgResult, err
}
