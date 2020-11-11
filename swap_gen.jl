using StatsBase, LinearAlgebra, Logging, InteractiveUtils

function swap_matrix(l24::Int64, l12::Int64; preferself::Bool=false, iters::Int64=10)
  totalparticipants = l24 + l12
  # rows are receivers
  # cols are donors
  self_mat = BitArray(Diagonal(fill(1, totalparticipants)))

  maxunique = l24 + (12*l12/l24) - !preferself
  @info "$maxunique max unique days for $l24 24-bottle participants and $l12 12-bottle participants"
  if maxunique < 23
    @error "Insufficient participants to ensure 24 unique bottles for 24-level participants"
  elseif 23 <= maxunique <= 24 & !preferself
    @info "While not preferred, 24 bottle level participants will need to receive one of their own bottles back"
  end

  # Determine how many bottles must come from l12 group to each l24 participant

  xer_min1 = Int64(max(ceil(maxunique) - l24, 0))
  xer_min2 = Int64(max(floor(maxunique) - l24, 0))
  fuller24 = min(l12 * 12 - l24 * xer_min2, l24)
  xer_min = vcat(fill(xer_min1, fuller24), fill(xer_min2, l24-fuller24))

  @info "Bottles required from 12-bottle participant pool for each 24-bottle participant" xer=xer_min

  taken_max = fill(24, l24)
  append!(taken_max, fill(12, l12))
  level12 = taken_max .== 12

  breakme = false
  didit = false
  local swap_mat

  for iteration = 1:iters
    breakme = false
    swap_mat = BitArray(fill(0, (totalparticipants, totalparticipants)))
    if preferself
      swap_mat .+= self_mat
    end
    @debug "Starting iteration $iteration"
    if any(xer_min .> 0)
      for receiver = 1:l24
        # Weight bottle selection based on quantity rem
        bottles_given = sum(swap_mat, dims=1)[:]
        sample_wv = Weights((taken_max .- bottles_given) .^4 .* level12 ./ taken_max)
        if sum(sample_wv .> 0) < xer_min[receiver]
          breakme = true
          break
        end
        sources = sample(1:totalparticipants, sample_wv, xer_min[receiver], replace=false)
        swap_mat[receiver, sources] .+= 1
      end
    end
    breakme && continue
    for receiver = 1:totalparticipants
      bottles_given = sum(swap_mat, dims=1)[:]
      not_already_given = .!swap_mat[receiver, :][:]
      not_self = .!self_mat[receiver, :][:]
      @debug "Starting $receiver..."
      if receiver <= l24
        required = 24 - sum(swap_mat[receiver, :])
      else
        required = 12 - sum(swap_mat[receiver, :])
      end
      eligible = not_already_given .& not_self
      sample_wv = Weights((taken_max .- bottles_given) .^ 4 .* eligible ./ taken_max)
      if sum(sample_wv .> 0) < required
        @debug "No longer avoiding self"
        eligible = not_already_given
        sample_wv = Weights((taken_max .- bottles_given) .^ 4 .* eligible ./ taken_max)
        if sum(sample_wv .> 0) < required
          breakme = true
          break
        end
      end
      sources = sample(1:totalparticipants, sample_wv, required, replace=false)
      swap_mat[receiver, sources] .+= 1
      @debug "Allocation complete" sources = swap_mat[receiver, :]'
      if receiver == totalparticipants
        @info "Successful allocation" iteration = iteration
        didit = true
      end
    end
    if didit
      break
    end
  end
  if didit
    return swap_mat
  else
    @info "Failed to generate a swap matrix"
    return nothing
  end
end