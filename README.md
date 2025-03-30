# Flow Seasons 2025 Spring

Here I try to add data visualization for the climbing comp: FlowSeasons organised by my favourite bouldergym: https://www.flowboulder.hu/

## Links

- Facebook: https://www.facebook.com/events/945118741114558
- Vertical Life: https://results.vertical-life.info/event/220/
- Overall Results: https://results.vertical-life.info/event/220/cr/2188

## Infrastructure

From idea to the first version of the working website took a couple of hours and cost me less than 2 eur, thanks to the carefully selected providers and simple infra:

- DNS registrator: `flowseries.lol` https://www.namecheap.com/  1.98 eur
- DNS servers: https://www.cloudflare.com/ - free
- Hosting(webserver): https://developers.cloudflare.com/pages/ - free
- Certificat(HTTPS): https://www.cloudflare.com/ - free
- Source Repo: https://github.com/lalyos/flowseasons.lol - free

## Dev Notes

Selfnotes, about how I produced this.

### Google Sheets

Importing the initial data for `routes.html`
```
alias r='source flow.sh'
r; stat
```

Importing the starting data for `rank.html`
```
cat results.json | jq -r '.ranking[]|"\(.rank)\t\(.score)\t\(.name)"'
```

Importing the starting data for `histogram.html`
```
cat results.json | jq -r '.ranking[].score'
```
