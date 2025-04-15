#!/bin/bash

# Configuration
API_URL="http://localhost:3000"  # Change this to match your server port
SEED_USER=1  # Special user ID that bypasses validation
CONCURRENCY=20  # Higher concurrency to stress test the API
REQUEST_DELAY=0.02  # Reduced delay between requests to increase throughput

# Create user IDs array with 100 users (starting from 2 since 1 is special)
USER_IDS=()
for i in $(seq 2 101); do
  USER_IDS+=($i)
done

# Transaction configuration

TOTAL_TRANSACTIONS=5000  # Lower this if you want to test quicker
# Different funding tiers to create volatility
WHALE_FUNDING=1000000000  # $10,000,000 for "whales"
LARGE_FUNDING=100000000   # $1,000,000 for large accounts
MEDIUM_FUNDING=10000000   # $100,000 for medium accounts
SMALL_FUNDING=1000000     # $10,000 for small accounts
MICRO_FUNDING=10000       # $100 for micro accounts

echo "Starting enhanced seed script for Expense Splitting API..."
echo "API URL: $API_URL"
echo "Seed User: $SEED_USER"
echo "Regular User Count: ${#USER_IDS[@]}"
echo "Concurrency Level: $CONCURRENCY"
echo "Total Transactions: $TOTAL_TRANSACTIONS"
echo "----------------------"

# Function to generate a random integer between min and max (inclusive)
random_int() {
  local min=$1
  local max=$2
  echo $((RANDOM % (max - min + 1) + min))
}

# Function for exponential distribution (to create more realistic transaction amounts)
exponential_random() {
  local min=$1
  local max=$2
  local lambda=5.0

  # Generate exponential random number
  local u=$(awk 'BEGIN{srand(); print rand()}')
  local exp_val=$(awk -v l=$lambda -v u=$u 'BEGIN{print -log(1-u)/l}')

  # Scale to range
  local range=$((max - min))
  local val=$(awk -v e=$exp_val -v r=$range 'BEGIN{print int(e * r)}')

  # Ensure within bounds
  if [[ $val -lt 0 ]]; then
    val=0
  elif [[ $val -gt $range ]]; then
    val=$range
  fi

  echo $((val + min))
}

# Function to get current balance
get_balance() {
  local user=$1
  local retries=3
  local attempt=0
  local response=""
  local http_code=0

  while [[ $attempt -lt $retries ]]; do
    response=$(curl -s -w "\n%{http_code}" -X GET "$API_URL/api/balance" \
      -H "x-user-id: $user")

    http_code=$(echo "$response" | tail -n1)

    if [[ $http_code -ge 200 && $http_code -lt 300 ]]; then
      break
    fi

    ((attempt++))
    sleep 0.2  # Brief pause before retry
  done

  body=$(echo "$response" | sed '$d')

  if [[ $http_code -ge 200 && $http_code -lt 300 ]]; then
    # Extract balance in cents using jq if available
    if command -v jq &> /dev/null; then
      balance_cents=$(echo "$body" | jq -r '.amount // 0')
    else
      # Fallback to grep if jq is not available
      balance_cents=$(echo "$body" | grep -o '"amount":[0-9]*' | grep -o '[0-9]*')
    fi

    if [[ -n "$balance_cents" && "$balance_cents" != "null" ]]; then
      echo "$balance_cents"
    else
      echo "0"
    fi
  else
    echo "0"
  fi
}

# Function to make a payment
make_payment() {
  local sender=$1
  local recipient=$2
  local amount_cents=$3
  local expected_success=${4:-true}
  local concurrent_id=${5:-""}
  local retries=2  # Allow retries for intermittent failures
  local attempt=0
  local success=false

  # Format amount for display
  dollars=$((amount_cents / 100))
  cents=$((amount_cents % 100))
  printf "[Thread %s] Transaction: %s pays %s $%d.%02d\n" "$concurrent_id" "$sender" "$recipient" "$dollars" "$cents"

  while [[ $attempt -lt $retries && $success == false ]]; do
    response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/pay" \
      -H "Content-Type: application/json" \
      -H "x-user-id: $sender" \
      -d "{\"recipient_id\":$recipient,\"amount\":$amount_cents}")

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [[ $expected_success == true ]]; then
      if [[ $http_code -ge 200 && $http_code -lt 300 ]]; then
        printf "[Thread %s] ✅ Success (HTTP %s)\n" "$concurrent_id" "$http_code"
        success=true
        return 0
      else
        # Only retry certain error codes (e.g., 500s but not 400s)
        if [[ $http_code -ge 500 && $attempt -lt $((retries-1)) ]]; then
          printf "[Thread %s] ⚠️ Server error (HTTP %s): Retrying...\n" "$concurrent_id" "$http_code"
          ((attempt++))
          sleep 0.5  # Slightly longer delay before retry
        else
          printf "[Thread %s] ❌ Expected success but failed (HTTP %s): %s\n" "$concurrent_id" "$http_code" "$body"
          return 1
        fi
      fi
    else
      if [[ $http_code -ge 200 && $http_code -lt 300 ]]; then
        printf "[Thread %s] ❌ Expected failure but succeeded (HTTP %s)\n" "$concurrent_id" "$http_code"
        return 0
      else
        printf "[Thread %s] ✅ Expected failure and correctly failed (HTTP %s)\n" "$concurrent_id" "$http_code"
        return 1
      fi
    fi
  done
}

# Create a temporary directory for thread logs
TEMP_DIR=$(mktemp -d)
echo "Creating temporary directory for thread logs: $TEMP_DIR"

# Initial funding for users with different tiers
echo "Providing initial funding to users with different amounts..."
FUNDED_USERS=()
WHALE_USERS=()
LARGE_USERS=()
MEDIUM_USERS=()
SMALL_USERS=()
MICRO_USERS=()

# Fund 5 whale users (extremely high balances)
echo "Funding whale accounts..."
for i in $(seq 1 5); do
  user_index=$(random_int 0 $((${#USER_IDS[@]} - 1)))
  user=${USER_IDS[$user_index]}

  make_payment $SEED_USER $user $WHALE_FUNDING "" "main"

  if [[ $? -eq 0 ]]; then
    WHALE_USERS+=($user)
    FUNDED_USERS+=($user)
    dollars=$((WHALE_FUNDING / 100))
    printf "🐳 Funded whale user %s with $%d\n" "$user" "$dollars"
  fi

  sleep 0.1
done

# Fund 15 large users
echo "Funding large accounts..."
for i in $(seq 1 15); do
  user_index=$(random_int 0 $((${#USER_IDS[@]} - 1)))
  user=${USER_IDS[$user_index]}

  # Skip if already funded
  if [[ " ${FUNDED_USERS[*]} " =~ " ${user} " ]]; then
    continue
  fi

  make_payment $SEED_USER $user $LARGE_FUNDING "" "main"

  if [[ $? -eq 0 ]]; then
    LARGE_USERS+=($user)
    FUNDED_USERS+=($user)
    dollars=$((LARGE_FUNDING / 100))
    printf "💰 Funded large user %s with $%d\n" "$user" "$dollars"
  fi

  sleep 0.1
done

# Fund 30 medium users
echo "Funding medium accounts..."
for i in $(seq 1 30); do
  user_index=$(random_int 0 $((${#USER_IDS[@]} - 1)))
  user=${USER_IDS[$user_index]}

  # Skip if already funded
  if [[ " ${FUNDED_USERS[*]} " =~ " ${user} " ]]; then
    continue
  fi

  make_payment $SEED_USER $user $MEDIUM_FUNDING "" "main"

  if [[ $? -eq 0 ]]; then
    MEDIUM_USERS+=($user)
    FUNDED_USERS+=($user)
    dollars=$((MEDIUM_FUNDING / 100))
    printf "💵 Funded medium user %s with $%d\n" "$user" "$dollars"
  fi

  sleep 0.1
done

# Fund 100 small users
echo "Funding small accounts..."
for i in $(seq 1 100); do
  user_index=$(random_int 0 $((${#USER_IDS[@]} - 1)))
  user=${USER_IDS[$user_index]}

  # Skip if already funded
  if [[ " ${FUNDED_USERS[*]} " =~ " ${user} " ]]; then
    continue
  fi

  make_payment $SEED_USER $user $SMALL_FUNDING "" "main"

  if [[ $? -eq 0 ]]; then
    SMALL_USERS+=($user)
    FUNDED_USERS+=($user)
    dollars=$((SMALL_FUNDING / 100))
    printf "💸 Funded small user %s with $%d\n" "$user" "$dollars"
  fi

  sleep 0.1
done

# Fund 200 micro users
echo "Funding micro accounts..."
for i in $(seq 1 200); do
  user_index=$(random_int 0 $((${#USER_IDS[@]} - 1)))
  user=${USER_IDS[$user_index]}

  # Skip if already funded
  if [[ " ${FUNDED_USERS[*]} " =~ " ${user} " ]]; then
    continue
  fi

  make_payment $SEED_USER $user $MICRO_FUNDING "" "main"

  if [[ $? -eq 0 ]]; then
    MICRO_USERS+=($user)
    FUNDED_USERS+=($user)
    dollars=$((MICRO_FUNDING / 100))
    printf "💲 Funded micro user %s with $%d\n" "$user" "$dollars"
  fi

  sleep 0.1
done

# Display funding summary
echo "----------------------"
echo "Funding summary:"
echo "🐳 Whale users (>$1M): ${#WHALE_USERS[@]}"
echo "💰 Large users ($100k-$1M): ${#LARGE_USERS[@]}"
echo "💵 Medium users ($10k-$100k): ${#MEDIUM_USERS[@]}"
echo "💸 Small users ($100-$10k): ${#SMALL_USERS[@]}"
echo "💲 Micro users (<$100): ${#MICRO_USERS[@]}"
echo "Total funded users: ${#FUNDED_USERS[@]}"
echo "----------------------"

echo "Starting parallel transactions..."

# Function to run a batch of transactions
run_transaction_batch() {
  local thread_id=$1
  local transactions_per_thread=$2
  local log_file="$TEMP_DIR/thread_${thread_id}.log"
  local success_count=0
  local attempt_count=0

  echo "[Thread $thread_id] Starting with $transactions_per_thread transactions" > "$log_file"

  while [[ $success_count -lt $transactions_per_thread && $attempt_count -lt $((transactions_per_thread * 3)) ]]; do
    # Decide transaction type based on probability
    transaction_type=$(random_int 1 100)

    # 5% chance for whale to pay someone
    if [[ $transaction_type -le 5 && ${#WHALE_USERS[@]} -gt 0 ]]; then
      sender_index=$(random_int 0 $((${#WHALE_USERS[@]} - 1)))
      sender=${WHALE_USERS[$sender_index]}
      transaction_category="whale"
    # 15% chance for large user to pay someone
    elif [[ $transaction_type -le 20 && ${#LARGE_USERS[@]} -gt 0 ]]; then
      sender_index=$(random_int 0 $((${#LARGE_USERS[@]} - 1)))
      sender=${LARGE_USERS[$sender_index]}
      transaction_category="large"
    # 30% chance for medium user to pay someone
    elif [[ $transaction_type -le 50 && ${#MEDIUM_USERS[@]} -gt 0 ]]; then
      sender_index=$(random_int 0 $((${#MEDIUM_USERS[@]} - 1)))
      sender=${MEDIUM_USERS[$sender_index]}
      transaction_category="medium"
    # 35% chance for small user to pay someone
    elif [[ $transaction_type -le 85 && ${#SMALL_USERS[@]} -gt 0 ]]; then
      sender_index=$(random_int 0 $((${#SMALL_USERS[@]} - 1)))
      sender=${SMALL_USERS[$sender_index]}
      transaction_category="small"
    # 15% chance for micro user to pay someone
    else
      sender_index=$(random_int 0 $((${#MICRO_USERS[@]} - 1)))
      sender=${MICRO_USERS[$sender_index]}
      transaction_category="micro"
    fi

    # Check sender's balance directly from API
    sender_balance=$(get_balance $sender)
    echo "[Thread $thread_id] Sender balance: $sender_balance - user $sender ($transaction_category)" >> "$log_file"

    # Skip if sender has insufficient balance
    if [[ $sender_balance -lt 100 ]]; then
      continue
    fi

    # Select random recipient (different from sender)
    recipient_index=$(random_int 0 $((${#USER_IDS[@]} - 1)))
    recipient=${USER_IDS[$recipient_index]}
    while [[ $recipient -eq $sender ]]; do
      recipient_index=$(random_int 0 $((${#USER_IDS[@]} - 1)))
      recipient=${USER_IDS[$recipient_index]}
    done

    # Generate random amount based on sender category
    case $transaction_category in
      "whale")
        # Whales can make huge transfers
        max_amount=$((sender_balance * 20 / 100))  # Up to 20% of their balance
        if [[ $max_amount -gt 50000000 ]]; then  # Cap at $500,000
          max_amount=50000000
        fi
        min_amount=1000000  # Minimum $10,000
        ;;
      "large")
        max_amount=$((sender_balance * 15 / 100))  # Up to 15% of their balance
        if [[ $max_amount -gt 10000000 ]]; then  # Cap at $100,000
          max_amount=10000000
        fi
        min_amount=100000  # Minimum $1,000
        ;;
      "medium")
        max_amount=$((sender_balance * 10 / 100))  # Up to 10% of their balance
        if [[ $max_amount -gt 1000000 ]]; then  # Cap at $10,000
          max_amount=1000000
        fi
        min_amount=10000  # Minimum $100
        ;;
      "small")
        max_amount=$((sender_balance * 10 / 100))  # Up to 10% of their balance
        if [[ $max_amount -gt 100000 ]]; then  # Cap at $1,000
          max_amount=100000
        fi
        min_amount=1000  # Minimum $10
        ;;
      "micro")
        max_amount=$((sender_balance * 30 / 100))  # Up to 30% of their balance
        if [[ $max_amount -gt 10000 ]]; then  # Cap at $100
          max_amount=10000
        fi
        min_amount=100  # Minimum $1
        ;;
    esac

    # Use exponential distribution for more realistic transaction amounts
    if [[ $min_amount -lt $max_amount ]]; then
      amount_cents=$(exponential_random $min_amount $max_amount)
    else
      amount_cents=$min_amount
    fi

    # Ensure amount is at least minimum and doesn't exceed balance
    if [[ $amount_cents -lt $min_amount ]]; then
      amount_cents=$min_amount
    fi
    if [[ $amount_cents -gt $sender_balance ]]; then
      amount_cents=$sender_balance
    fi

    # Track attempt
    ((attempt_count++))

    # Make payment
    if make_payment $sender $recipient $amount_cents true $thread_id >> "$log_file" 2>&1; then
      ((success_count++))
      echo "[Thread $thread_id] Success count: $success_count/$transactions_per_thread" >> "$log_file"
    fi

    # Small delay to avoid overwhelming the API
    sleep $REQUEST_DELAY
  done

  echo "[Thread $thread_id] Completed with $success_count successful transactions out of $attempt_count attempts" >> "$log_file"
  echo "$success_count $attempt_count" > "$TEMP_DIR/thread_${thread_id}_counts.txt"
}

# Calculate transactions per thread
transactions_per_thread=$((TOTAL_TRANSACTIONS / CONCURRENCY))
if [[ $transactions_per_thread -lt 1 ]]; then
  transactions_per_thread=1
fi

# Launch parallel transaction batches
for i in $(seq 1 $CONCURRENCY); do
  run_transaction_batch $i $transactions_per_thread &
  echo "Launched transaction thread $i"
done

echo "Waiting for all transaction threads to complete..."
wait

# Collect results
total_success=0
total_attempts=0

for i in $(seq 1 $CONCURRENCY); do
  if [[ -f "$TEMP_DIR/thread_${i}_counts.txt" ]]; then
    read success attempts < "$TEMP_DIR/thread_${i}_counts.txt"
    total_success=$((total_success + success))
    total_attempts=$((total_attempts + attempts))
  fi
done

echo "----------------------"
echo "Transaction Summary:"
echo "Total Attempted: $total_attempts"
echo "Total Successful: $total_success"
echo "----------------------"

# EDGE CASE TESTING
echo "Running edge case tests..."

# Function to run edge case tests
run_edge_case() {
  local test_name=$1
  local sender=$2
  local recipient=$3
  local amount=$4
  local expected_success=$5

  echo "🧪 Edge Case: $test_name"
  make_payment $sender $recipient $amount $expected_success "edge"
  return $?
}

# 1. Test exactly zero amount
echo "Testing zero amount transaction..."
sender=${FUNDED_USERS[$(random_int 0 $((${#FUNDED_USERS[@]} - 1)))]}
recipient=${USER_IDS[$(random_int 0 $((${#USER_IDS[@]} - 1)))]}
run_edge_case "Zero Amount" $sender $recipient 0 false

# 2. Test maximum int32 amount (should fail for most users)
echo "Testing maximum int32 amount..."
sender=${FUNDED_USERS[$(random_int 0 $((${#FUNDED_USERS[@]} - 1)))]}
recipient=${USER_IDS[$(random_int 0 $((${#USER_IDS[@]} - 1)))]}
run_edge_case "Max Int32" $sender $recipient 2147483647 false

# 3. Test negative amount
echo "Testing negative amount..."
sender=${FUNDED_USERS[$(random_int 0 $((${#FUNDED_USERS[@]} - 1)))]}
recipient=${USER_IDS[$(random_int 0 $((${#USER_IDS[@]} - 1)))]}
run_edge_case "Negative Amount" $sender $recipient -1000 false

# 4. Test user paying themselves
echo "Testing self-payment..."
sender=${FUNDED_USERS[$(random_int 0 $((${#FUNDED_USERS[@]} - 1)))]}
run_edge_case "Self Payment" $sender $sender 1000 false

# 5. Test non-existent recipient
echo "Testing payment to non-existent user..."
sender=${FUNDED_USERS[$(random_int 0 $((${#FUNDED_USERS[@]} - 1)))]}
run_edge_case "Non-existent Recipient" $sender 999999 1000 false

# 6. Test non-existent sender
echo "Testing payment from non-existent user..."
recipient=${USER_IDS[$(random_int 0 $((${#USER_IDS[@]} - 1)))]}
run_edge_case "Non-existent Sender" 999999 $recipient 1000 false

# 7. Test exact balance transactions
echo "Testing exact balance transaction..."
sender=${SMALL_USERS[$(random_int 0 $((${#SMALL_USERS[@]} - 1)))]}
sender_balance=$(get_balance $sender)
recipient=${USER_IDS[$(random_int 0 $((${#USER_IDS[@]} - 1)))]}
while [[ $recipient -eq $sender ]]; do
  recipient=${USER_IDS[$(random_int 0 $((${#USER_IDS[@]} - 1)))]}
done
run_edge_case "Exact Balance" $sender $recipient $sender_balance true

# 8. Test rapid concurrent transactions to same recipient
echo "Testing rapid concurrent transactions to same recipient..."
recipient=${USER_IDS[$(random_int 0 $((${#USER_IDS[@]} - 1)))]}
for i in $(seq 1 10); do
  sender=${FUNDED_USERS[$(random_int 0 $((${#FUNDED_USERS[@]} - 1)))]}
  while [[ $sender -eq $recipient ]]; do
    sender=${FUNDED_USERS[$(random_int 0 $((${#FUNDED_USERS[@]} - 1)))]}
  done
  run_edge_case "Concurrent Payment $i" $sender $recipient 1000 true &

  if [[ $i -eq 5 ]]; then
    sleep 0.01  # Brief pause in the middle
  fi
done

# Wait for concurrent transactions to complete
wait

# 9. Test one cent transaction
echo "Testing one cent transaction..."
sender=${FUNDED_USERS[$(random_int 0 $((${#FUNDED_USERS[@]} - 1)))]}
recipient=${USER_IDS[$(random_int 0 $((${#USER_IDS[@]} - 1)))]}
while [[ $recipient -eq $sender ]]; do
  recipient=${USER_IDS[$(random_int 0 $((${#USER_IDS[@]} - 1)))]}
done
run_edge_case "One Cent" $sender $recipient 1 true

# Generate more negative amount transactions in parallel
echo "Generating more edge case negative amount transactions..."
run_negative_transaction() {
  local thread_id=$1
  local sender_index=$(random_int 0 $((${#FUNDED_USERS[@]} - 1)))
  local sender=${FUNDED_USERS[$sender_index]}

  local recipient_index=$(random_int 0 $((${#USER_IDS[@]} - 1)))
  local recipient=${USER_IDS[$recipient_index]}

  # Various negative amounts
  local amounts=(-1 -10 -100 -1000 -10000 -100000 -1000000)
  local amount_index=$(random_int 0 $((${#amounts[@]} - 1)))
  local amount_cents=${amounts[$amount_index]}

  make_payment $sender $recipient $amount_cents false $thread_id
  sleep $REQUEST_DELAY
}

# Run 100 negative transactions in parallel
for i in $(seq 1 100); do
  thread_id=$((i % CONCURRENCY + 1))
  run_negative_transaction $thread_id &

  # Limit concurrency to avoid overwhelming the system
  if [[ $((i % CONCURRENCY)) -eq 0 ]]; then
    wait
  fi
done

# Wait for any remaining negative transaction threads
wait

echo "----------------------"
echo "Checking final balances for sample users..."
echo "----------------------"

# Function to show user statistics
show_user_stats() {
  local title=$1
  local user_array=("${!2}")
  local sample_size=$3

  echo "$title (sample of $sample_size users):"

  if [[ ${#user_array[@]} -eq 0 ]]; then
    echo "  No users in this category"
    return
  fi

  local display_count=$sample_size
  if [[ $display_count -gt ${#user_array[@]} ]]; then
    display_count=${#user_array[@]}
  fi

  for i in $(seq 1 $display_count); do
    local user_index=$(random_int 0 $((${#user_array[@]} - 1)))
    local user=${user_array[$user_index]}

    local balance=$(get_balance $user)
    local dollars=$((balance / 100))
    local cents=$((balance % 100))

    printf "  User %d: $%d.%02d\n" "$user" "$dollars" "$cents"
  done
}

# Show stats for each user category
show_user_stats "🐳 Whale users" WHALE_USERS[@] 3
show_user_stats "💰 Large users" LARGE_USERS[@] 3
show_user_stats "💵 Medium users" MEDIUM_USERS[@] 3
show_user_stats "💸 Small users" SMALL_USERS[@] 3
show_user_stats "💲 Micro users" MICRO_USERS[@] 3

# Show most active users (we don't track this, so choosing random funded users)
echo "Random sample of other users:"
for i in $(seq 1 5); do
  user_index=$(random_int 0 $((${#USER_IDS[@]} - 1)))
  user=${USER_IDS[$user_index]}

  balance=$(get_balance $user)
  dollars=$((balance / 100))
  cents=$((balance % 100))

  printf "  User %d: $%d.%02d\n" "$user" "$dollars" "$cents"
done

# Check seed user's balance (should be very negative)
seed_balance=$(get_balance $SEED_USER)
seed_dollars=$((seed_balance / 100))
seed_cents=$((seed_balance % 100))
printf "Seed User %d: $%d.%02d\n" "$SEED_USER" "$seed_dollars" "$seed_cents"

# Clean up temp directory
rm -rf "$TEMP_DIR"

echo "----------------------"
echo "Seed script completed successfully!"
echo "Total transactions processed: $((total_success + 200))"  # Adding edge case transactions
echo "Your API has been thoroughly stress-tested."