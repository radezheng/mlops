import os

def init():
    global test_var
    test_var="global out."
    print("init...")

def run(mini_batch):
    results = []
    print("runing...")
    for d in mini_batch:
        result = f"Processed data: {test_var}, {d}"
        results.append(result)
    
    
    return results
