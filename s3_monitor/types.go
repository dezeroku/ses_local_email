package main

type ObjectCreatedEventDetailObject struct {
	Key       string `json:"key"`
	Size      int    `json:"size"`
	Etag      string `json:"etag"`
	Sequencer string `json:"sequencer"`
}

type ObjectCreatedEventDetail struct {
	Version         string                         `json:"version"`
	Bucket          map[string]string              `json:"bucket"`
	Object          ObjectCreatedEventDetailObject `json:"object"`
	RequestID       string                         `json:"request-id"`
	Requester       string                         `json:"requester"`
	SourceIPAddress string                         `json:"source-ip-address"`
	Reason          string                         `json:"reason"`
}

type ObjectCreatedEvent struct {
	Version    string                   `json:"version"`
	Id         string                   `json:"id"`
	DetailType string                   `json:"detail-type"`
	Source     string                   `json:"source"`
	Account    string                   `json:"account"`
	Time       string                   `json:"time"`
	Region     string                   `json:"region"`
	Resources  []string                 `json:"resources"`
	Detail     ObjectCreatedEventDetail `json:"detail"`
}
