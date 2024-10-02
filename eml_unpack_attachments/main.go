package main

import (
	"io/ioutil"
	"log"
	"os"
	"path"
	"strings"

	"github.com/fsnotify/fsnotify"
	"github.com/mnako/letters"
)

var (
	inputDirectoryEnvVar  = "INPUT_DIRECTORY"
	outputDirectoryEnvVar = "OUTPUT_DIRECTORY"
)

func requireEnvVariable(name string) string {
	value, present := os.LookupEnv(name)
	if !present {
		log.Fatalf("Env variable %s is required, but not present", name)
	}
	return value
}

func processNewFile(filename string, outputDirectory string) error {
	log.Print("Processing file: ", filename)

	if !strings.HasSuffix(filename, ".eml") {
		log.Print("File doesn't have .eml extension, skipping: ", filename)
		return nil
	}

	fileInfo, err := os.Stat(filename)
	if err != nil {
		return err
	}

	if fileInfo.IsDir() {
		log.Print("File is a directory, skipping: ", filename)
		return nil
	}

	reader, err := os.Open(filename)
	if err != nil {
		return err
	}
	defer reader.Close()

	email, err := letters.ParseEmail(reader)
	if err != nil {
		return err
	}

	log.Printf("FROM: %s TO: %s SUBJECT: %s\n", email.Headers.From, email.Headers.To, email.Headers.Subject)
	if len(email.AttachedFiles) > 0 {
		log.Print("Attachments:")
		for _, a := range email.AttachedFiles {
			attachmentName := a.ContentType.Params["name"]
			log.Print(attachmentName)
			err := os.WriteFile(path.Join(outputDirectory, attachmentName), a.Data, 0644)
			if err != nil {
				return err
			}
		}
	} else {
		log.Print("No attachments found")
	}

	log.Print("Removing file: ", filename)
	err = os.Remove(filename)
	if err != nil {
		return err
	}
	return nil
}

func main() {
	inputDirectory := requireEnvVariable(inputDirectoryEnvVar)
	outputDirectoryVar := requireEnvVariable(outputDirectoryEnvVar)
	outputDirectory := path.Clean(outputDirectoryVar)

	os.MkdirAll(outputDirectory, os.ModePerm)

	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log.Fatal(err)
	}
	defer watcher.Close()

	go func() {
		for {
			select {
			case event, ok := <-watcher.Events:
				if !ok {
					return
				}
				if event.Has(fsnotify.Create) {
					log.Print("New file: ", event.Name)

					err := processNewFile(event.Name, outputDirectory)
					if err != nil {
						log.Print(err)
					}
				}
			case err, ok := <-watcher.Errors:
				if !ok {
					return
				}
				log.Fatal(err)
			}
		}
	}()

	err = watcher.Add(inputDirectory)
	if err != nil {
		log.Fatal(err)
	}

	// TODO: a possible race condition here between fsnotify based logic and ReadDir
	// Shouldn't bite us for now anyway as the names are unique, but it's something to keep in mind
	// We need this call here, as fsnotify is only looking for new files, but we want to consider
	// the already existing ones too
	files, err := ioutil.ReadDir(inputDirectory)
	if err != nil {
		log.Fatal(err)
	}

	for _, file := range files {
		err := processNewFile(path.Join(inputDirectory, file.Name()), outputDirectory)
		if err != nil {
			log.Fatal(err)
		}
	}

	// Block main goroutine forever.
	<-make(chan struct{})
}
