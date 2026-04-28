# Ingest Prompt Templates

These are the mental frameworks to use when distilling a source into wiki pages.

## Knowledge Extraction Frame

When reading a source document, ask yourself:

1. **What are the 3-5 most important ideas in this document?**
   These become concepts pages or updates to existing concept pages.

2. **Who or what is mentioned that deserves its own page?**
   People, tools, organizations, projects → entity pages.

3. **What does this document teach you how to do?**
   Procedures, workflows, techniques → skills pages.

4. **What claims does this document make?**
   Each claim needs a source attribution. If it contradicts an existing wiki claim, note the contradiction.

5. **How does this connect to what the wiki already knows?**
   This is the most important question. The value of the wiki compounds through connections.

## Mechanism Flow Frame

For sources that explain algorithms, protocols, replication schemes, transaction flows, elections, recovery paths, routing, consistency reads, or conflict handling, the wiki page must preserve the mechanism, not just the vocabulary. Extract:

1. **Actors and state**
   Name the participants and local state they keep, such as leader/follower, proposer/acceptor, term, log index, commit index, version vector, or read/write quorum.

2. **Happy-path sequence**
   Write the ordered flow: who initiates, what message or state transition happens, what each receiver records, when acknowledgements matter, and when the operation is considered complete.

3. **Failure branches**
   Capture the important branch points: timeout, rejected vote, missing log, stale leader, network partition, conflicting write, stale read, member-change interruption, or failed quorum.

4. **Safety and liveness invariants**
   Explain why the flow is correct: quorum intersection, monotonic terms, one vote per term, log matching, current-term commit, vector-clock dominance, read/write overlap, or application-level conflict merge.

5. **Boundaries and tradeoffs**
   Record what the mechanism does not guarantee and what it sacrifices, such as latency, availability, strict freshness, storage overhead, or reliance on clock assumptions.

6. **Figure reading and optional diagrams**
   If the source has figures, screenshots, sequence diagrams, topology diagrams, or captions that carry explanatory content, read that visual information as part of extraction. Use the caption, surrounding prose, and the image itself when necessary. Add Mermaid only when a diagram will make the distilled note easier to understand or verify; not every source figure needs to be recreated. Use `sequenceDiagram` for RPC/message order, `flowchart` for state transitions or failure branches, and graph/set diagrams for quorum overlap, partitions, or topology.

If a page is mechanism-heavy and only contains a `Key Ideas` bullet list, the ingest is incomplete. Add sections such as `工作流程`, `时序流程`, `失败与恢复路径`, or `安全性约束`; add diagrams selectively when they clarify the flow.

## Synthesis Frame

When a new source covers ground that existing pages already cover:

- Don't duplicate — synthesize
- If the new source agrees with existing content, strengthen the claims with additional attribution
- If it disagrees, create an "Open Questions" or "Debate" section noting both positions
- If it adds nuance, weave it into the existing narrative

## Cross-Reference Discovery

After extracting knowledge, look for these connection patterns:

- **Is-a**: "Transformers are a type of neural network" → link from transformer page to neural-network page
- **Uses**: "RLHF uses reward models" → link from RLHF to reward-models
- **Contrasts-with**: "CNNs vs. Transformers for vision" → mutual links
- **Part-of**: "Attention is a component of transformers" → link from attention to transformers
- **Created-by**: "Transformers were introduced by Vaswani et al." → link to entity page
- **Applied-in**: "Transformers are used in GPT" → link from transformers to GPT
