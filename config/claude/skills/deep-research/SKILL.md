---
name: deep-research
description: Use when asked to find papers on a topic, do a literature search, survey state-of-the-art, or find related work. Triggers on "find papers about", "literature search", "what papers exist on", "research the field of", "state of the art on".
---

# Deep Research

Find the 15-20 most relevant academic papers on a research question.

## Searching

Give each subagent the **full research question verbatim** and the **scoring rubric below copy-pasted word-for-word**. Do not paraphrase, reword, or adapt the rubric — copy it exactly. Every agent scores against the original research question, not against whatever subtopic it happens to be exploring. Do not pre-specify search queries or topic silos — spawn redundant subagents that each independently reason about the question and decide their own search strategy. Redundancy is the point: each agent will naturally explore different angles, and overlap is fine.

Free APIs to hit via WebFetch:

- **Semantic Scholar API** — `https://api.semanticscholar.org/graph/v1/paper/search?query=QUERY&limit=20&fields=title,authors,year,abstract,url,citationCount,referenceCount,externalIds` — also `/recommendations/v1/papers/` with a seed paper ID.
- **arXiv API** — `http://export.arxiv.org/api/query?search_query=all:QUERY&max_results=20`
- **OpenAlex API** — `https://api.openalex.org/works?search=QUERY&per_page=20`
- **WebSearch** — for surveys, blog posts, awesome-lists that reference papers.

## Relevance filtering

Score every paper 1-10 for how directly it answers the **specific research question**. Be ruthlessly strict:

- **9-10**: This paper is specifically about the thing being asked. You would cite it in the first paragraph of a paper on this topic.
- **8**: Directly relevant technique or result. Core reading for this question.
- **5-7**: Related area but doesn't directly address the question. Most papers land here. Do not include these.
- **1-4**: Tangential keyword match.

Only include papers scoring 8+. Most keyword search results will score 5-7 and should be dropped.

The 15-20 paper cap applies to the **final synthesized output**, not to individual subagents. Subagents should return all genuinely 8+ papers they find. The orchestrator deduplicates and selects the top 15-20 at the end. A bloated final list of 50+ papers is a complete waste of the user's time. Aim for a very low false positive rate.

## Following citations

For the most relevant papers found, follow their references and citations via Semantic Scholar:
- `https://api.semanticscholar.org/graph/v1/paper/{paper_id}/references?fields=title,authors,year,abstract,url,citationCount`
- `https://api.semanticscholar.org/graph/v1/paper/{paper_id}/citations?fields=title,authors,year,abstract,url,citationCount`

Which papers to follow should be based on what the search actually found — don't pre-select. Also skim related work sections of promising papers for leads APIs miss.

## Output

Group by category. Within each category, sort by relevance score descending. For each paper:
- Title, authors, year, venue, link, relevance score
- 2-3 sentence summary of what the paper actually does and finds — enough that the reader understands why it matters for their question without having to open it
