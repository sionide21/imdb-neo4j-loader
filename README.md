Load IMDB data into neo4j
=========================

Inspired by the sample dataset used in the neo4j tutorials, this script loads all actors and movies into a neo4j database.


## Usage

I recommend you install [pv](http://www.ivarch.com/programs/pv.shtml) to get a nice progress bar. After that, simply pipe the files from [IMDB](http://www.imdb.com/interfaces) into `data_loader.rb`:

```sh
pv actors.list | ./data_loader <neo4j host>
pv actresses.list | ./data_loader <neo4j host>
```
