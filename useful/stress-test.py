import torch
import time

# Set device to GPU (CUDA)
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# Function to perform matrix multiplication to stress the GPU
def stress_test_gpu(size, its):
    # Create large random tensors
    a = torch.randn(size, size, device=device)
    b = torch.randn(size, size, device=device)

    # Perform matrix multiplication in a loop
    for i in range(its):
        # Measure start time

        # Matrix multiplication
        c = torch.matmul(a, b)

        # Optionally print the time taken for each operation (uncomment for debugging)
        # print(f"Time taken: {time.time() - start_time} seconds")

if __name__ == "__main__":
    # Set the size of the matrix (increase for more stress)
    matrix_size = 32768  # Adjust size as needed
    iterations = 200

    print(f"Starting GPU stress test with matrix size: {matrix_size}")
    stress_test_gpu(matrix_size, iterations)

