note
	description: "[
		Similarity and distance calculations for vector embeddings.

		Provides common metrics for comparing vectors:
			- Cosine Similarity: Angle between vectors (-1 to 1)
			- Euclidean Distance: Straight-line distance
			- Manhattan Distance: Taxicab/L1 distance
			- Dot Product: Inner product of vectors

		Usage:
			create sim.make
			score := sim.cosine_similarity (vec1, vec2)
			dist := sim.euclidean_distance (vec1, vec2)

		Cosine Similarity:
			- 1.0 = identical direction
			- 0.0 = orthogonal (no similarity)
			- -1.0 = opposite direction

		For normalized vectors, cosine similarity equals dot product.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_SIMILARITY

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize similarity calculator
		do
			-- Nothing to initialize
		end

feature -- Similarity Metrics

	cosine_similarity (a_vec1, a_vec2: SIMPLE_SQL_VECTOR): REAL_64
			-- Cosine similarity between vectors
			-- Range: -1.0 (opposite) to 1.0 (identical direction)
			-- Returns 0.0 for zero vectors
		require
			same_dimension: a_vec1.dimension = a_vec2.dimension
		local
			dot, mag1, mag2, denom: REAL_64
		do
			dot := a_vec1.dot_product (a_vec2)
			mag1 := a_vec1.magnitude
			mag2 := a_vec2.magnitude
			denom := mag1 * mag2

			if denom > Tolerance then
				Result := dot / denom
				-- Clamp to [-1, 1] to handle floating point errors
				Result := Result.max (-1.0).min (1.0)
			else
				Result := 0.0  -- Zero vector case
			end
		ensure
			in_range: Result >= -1.0 and Result <= 1.0
		end

	euclidean_distance (a_vec1, a_vec2: SIMPLE_SQL_VECTOR): REAL_64
			-- Euclidean (L2) distance between vectors
		require
			same_dimension: a_vec1.dimension = a_vec2.dimension
		local
			sum, diff: REAL_64
			i: INTEGER
		do
			from i := 1 until i > a_vec1.dimension loop
				diff := a_vec1 [i] - a_vec2 [i]
				sum := sum + diff * diff
				i := i + 1
			variant
				a_vec1.dimension - i + 1
			end
			Result := {DOUBLE_MATH}.sqrt (sum)
		ensure
			non_negative: Result >= 0.0
			zero_for_same: a_vec1.is_equal (a_vec2) implies Result < Tolerance
			symmetric: (Result - euclidean_distance (a_vec2, a_vec1)).abs < Tolerance
		end

	manhattan_distance (a_vec1, a_vec2: SIMPLE_SQL_VECTOR): REAL_64
			-- Manhattan (L1/taxicab) distance between vectors
		require
			same_dimension: a_vec1.dimension = a_vec2.dimension
		local
			i: INTEGER
		do
			from i := 1 until i > a_vec1.dimension loop
				Result := Result + (a_vec1 [i] - a_vec2 [i]).abs
				i := i + 1
			variant
				a_vec1.dimension - i + 1
			end
		ensure
			non_negative: Result >= 0.0
			zero_for_same: a_vec1.is_equal (a_vec2) implies Result < Tolerance
			symmetric: (Result - manhattan_distance (a_vec2, a_vec1)).abs < Tolerance
			at_least_euclidean: Result >= euclidean_distance (a_vec1, a_vec2) - Tolerance
		end

	dot_product (a_vec1, a_vec2: SIMPLE_SQL_VECTOR): REAL_64
			-- Dot product (inner product) of vectors
		require
			same_dimension: a_vec1.dimension = a_vec2.dimension
		do
			Result := a_vec1.dot_product (a_vec2)
		ensure
			symmetric: (Result - a_vec2.dot_product (a_vec1)).abs < Tolerance
		end

feature -- Derived Metrics

	angular_distance (a_vec1, a_vec2: SIMPLE_SQL_VECTOR): REAL_64
			-- Angular distance: 1 - cosine_similarity
			-- Range: 0.0 (identical) to 2.0 (opposite)
		require
			same_dimension: a_vec1.dimension = a_vec2.dimension
		do
			Result := 1.0 - cosine_similarity (a_vec1, a_vec2)
		ensure
			in_range: Result >= 0.0 and Result <= 2.0
		end

	squared_euclidean_distance (a_vec1, a_vec2: SIMPLE_SQL_VECTOR): REAL_64
			-- Squared Euclidean distance (faster, avoids sqrt)
		require
			same_dimension: a_vec1.dimension = a_vec2.dimension
		local
			diff: REAL_64
			i: INTEGER
		do
			from i := 1 until i > a_vec1.dimension loop
				diff := a_vec1 [i] - a_vec2 [i]
				Result := Result + diff * diff
				i := i + 1
			variant
				a_vec1.dimension - i + 1
			end
		ensure
			non_negative: Result >= 0.0
			consistent_with_euclidean: (Result - euclidean_distance (a_vec1, a_vec2) ^ 2).abs < Tolerance
		end

feature -- Batch Operations

	pairwise_cosine_similarity (a_vectors: ARRAY [SIMPLE_SQL_VECTOR]): ARRAY2 [REAL_64]
			-- Compute cosine similarity matrix for all pairs
		require
			not_empty: not a_vectors.is_empty
			same_dimensions: across a_vectors as ic all ic.dimension = a_vectors [a_vectors.lower].dimension end
		local
			n, i, j: INTEGER
		do
			n := a_vectors.count
			create Result.make_filled (0.0, n, n)
			from i := 1 until i > n loop
				from j := i until j > n loop
					Result [i, j] := cosine_similarity (a_vectors [a_vectors.lower + i - 1], a_vectors [a_vectors.lower + j - 1])
					Result [j, i] := Result [i, j]  -- Symmetric
					j := j + 1
				end
				i := i + 1
			end
		ensure
			symmetric: Result.height = Result.width
			correct_size: Result.height = a_vectors.count
		end

	rank_by_similarity (a_query: SIMPLE_SQL_VECTOR; a_candidates: ARRAY [SIMPLE_SQL_VECTOR]): ARRAY [TUPLE [index: INTEGER; score: REAL_64]]
			-- Rank candidates by cosine similarity to query (highest first)
		require
			candidates_not_empty: not a_candidates.is_empty
			same_dimension: across a_candidates as ic all ic.dimension = a_query.dimension end
		local
			l_scores: ARRAYED_LIST [TUPLE [index: INTEGER; score: REAL_64]]
			i: INTEGER
		do
			create l_scores.make (a_candidates.count)
			from i := a_candidates.lower until i > a_candidates.upper loop
				l_scores.extend ([i, cosine_similarity (a_query, a_candidates [i])])
				i := i + 1
			end

			-- Sort by score descending
			sort_scores_descending (l_scores)

			create Result.make_from_array (l_scores.to_array)
		ensure
			same_count: Result.count = a_candidates.count
		end

	find_most_similar (a_query: SIMPLE_SQL_VECTOR; a_candidates: ARRAY [SIMPLE_SQL_VECTOR]): INTEGER
			-- Index of most similar candidate (in original array bounds)
		require
			candidates_not_empty: not a_candidates.is_empty
			same_dimension: across a_candidates as ic all ic.dimension = a_query.dimension end
		local
			best_score, score: REAL_64
			i: INTEGER
		do
			Result := a_candidates.lower
			best_score := cosine_similarity (a_query, a_candidates [Result])

			from i := a_candidates.lower + 1 until i > a_candidates.upper loop
				score := cosine_similarity (a_query, a_candidates [i])
				if score > best_score then
					best_score := score
					Result := i
				end
				i := i + 1
			end
		ensure
			valid_index: Result >= a_candidates.lower and Result <= a_candidates.upper
		end

	average_similarity (a_vectors: ARRAY [SIMPLE_SQL_VECTOR]): REAL_64
			-- Average pairwise cosine similarity
		require
			at_least_two: a_vectors.count >= 2
			same_dimensions: across a_vectors as ic all ic.dimension = a_vectors [a_vectors.lower].dimension end
		local
			total: REAL_64
			count, i, j: INTEGER
		do
			from i := a_vectors.lower until i >= a_vectors.upper loop
				from j := i + 1 until j > a_vectors.upper loop
					total := total + cosine_similarity (a_vectors [i], a_vectors [j])
					count := count + 1
					j := j + 1
				end
				i := i + 1
			end
			if count > 0 then
				Result := total / count
			end
		end

feature -- Utility

	is_similar (a_vec1, a_vec2: SIMPLE_SQL_VECTOR; a_threshold: REAL_64): BOOLEAN
			-- Are vectors similar (cosine similarity >= threshold)?
		require
			same_dimension: a_vec1.dimension = a_vec2.dimension
			valid_threshold: a_threshold >= -1.0 and a_threshold <= 1.0
		do
			Result := cosine_similarity (a_vec1, a_vec2) >= a_threshold
		ensure
			definition: Result = (cosine_similarity (a_vec1, a_vec2) >= a_threshold)
			symmetric: Result = is_similar (a_vec2, a_vec1, a_threshold)
		end

	is_near (a_vec1, a_vec2: SIMPLE_SQL_VECTOR; a_max_distance: REAL_64): BOOLEAN
			-- Are vectors near (Euclidean distance <= max)?
		require
			same_dimension: a_vec1.dimension = a_vec2.dimension
			positive_distance: a_max_distance >= 0.0
		do
			Result := euclidean_distance (a_vec1, a_vec2) <= a_max_distance
		ensure
			definition: Result = (euclidean_distance (a_vec1, a_vec2) <= a_max_distance)
			symmetric: Result = is_near (a_vec2, a_vec1, a_max_distance)
		end

feature {NONE} -- Implementation

	sort_scores_descending (a_list: ARRAYED_LIST [TUPLE [index: INTEGER; score: REAL_64]])
			-- Sort in place by score descending using library quick sort
		local
			l_sorter: QUICK_SORTER [TUPLE [index: INTEGER; score: REAL_64]]
			l_comparator: AGENT_PART_COMPARATOR [TUPLE [index: INTEGER; score: REAL_64]]
		do
			create l_comparator.make (agent compare_scores_descending)
			create l_sorter.make (l_comparator)
			l_sorter.sort (a_list)
		ensure
			same_count: a_list.count = old a_list.count
		end

	compare_scores_descending (a, b: TUPLE [index: INTEGER; score: REAL_64]): BOOLEAN
			-- Is `a` considered less than `b` for descending sort?
			-- Returns True if a.score > b.score (higher scores come first)
		do
			Result := a.score > b.score
		end

	Tolerance: REAL_64 = 1.0e-10
			-- Floating point comparison tolerance

invariant
	tolerance_positive: Tolerance > 0.0

end
