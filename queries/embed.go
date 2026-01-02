package queries

import "embed"

//go:embed game/*.sql
var GameQueries embed.FS

func Load(path string) string {
	data, err := GameQueries.ReadFile(path)
	if err != nil {
		panic("failed to load query: " + path)
	}
	return string(data)
}
