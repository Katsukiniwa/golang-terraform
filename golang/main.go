package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

func healthHandler(w http.ResponseWriter, _ *http.Request) {
	hello := []byte("pong")

	_, err := w.Write(hello)
	if err != nil {
		log.Fatal(err)
	}
}

func rootHandler(w http.ResponseWriter, _ *http.Request) {
	hello := []byte("Hello, World! I like turtles.")

	log.Println("called root handler")

	_, err := w.Write(hello)
	if err != nil {
		log.Fatal(err)
	}
}

func getBucketList(w http.ResponseWriter, _ *http.Request) {
	type S3ObjectURLs struct {
		URLs []string `json:"urls"`
	}

	cfg, err := config.LoadDefaultConfig(
		context.TODO(),
	)
	if err != nil {
		log.Fatal(err)
	}

	client := s3.NewFromConfig(cfg)

	bucketName := "katsukiniwa-golang-terraform"

	output, err := client.ListObjectsV2(context.TODO(), &s3.ListObjectsV2Input{
		Bucket: aws.String(bucketName),
	})
	if err != nil {
		log.Fatal(err)
	}

	var urls []string

	for _, object := range output.Contents {
		url := fmt.Sprintf("https://%s.s3.ap-northeast-1.amazonaws.com/%s", bucketName, url.QueryEscape(aws.ToString(object.Key)))
		urls = append(urls, url)
	}

	response := S3ObjectURLs{URLs: urls}

	w.Header().Set("Content-Type", "application/json")

	if err := json.NewEncoder(w).Encode(response); err != nil {
		http.Error(w, fmt.Sprintf("failed to encode JSON: %v", err), http.StatusInternalServerError)

		return
	}
}

func timeHandler(w http.ResponseWriter, _ *http.Request) {
	ct := time.Now().Format("2006-01-02 15:04:05")

	_, err := w.Write([]byte(ct))
	if err != nil {
		log.Fatal(err)
	}
}

func main() {
	log.Println("Starting server on port 8080...")

	server := http.Server{
		Addr: ":8080",
	}

	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/time", timeHandler)
	http.HandleFunc("/", rootHandler)
	http.HandleFunc("/buckets", getBucketList)

	err := server.ListenAndServe()
	if err != nil {
		log.Fatal(err)
	}
}
