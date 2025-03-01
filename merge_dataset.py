import os
import shutil
import random

# Paths to existing datasets
datasets = ["drone_dataset"]

# New dataset structure
base_path = "./datasets/airborne_threat_dataset"
os.makedirs(base_path, exist_ok=True)

for sub in ["train", "val", "test"]:
    os.makedirs(os.path.join(base_path, "images", sub), exist_ok=True)
    os.makedirs(os.path.join(base_path, "labels", sub), exist_ok=True)

# Function to distribute files randomly
def split_data(dataset_path):
    image_dir = os.path.join(dataset_path, "images")
    label_dir = os.path.join(dataset_path, "labels")

    images = sorted(os.listdir(image_dir))
    random.shuffle(images)

    split_ratios = [0.7, 0.2, 0.1]  # Train 70%, Val 20%, Test 10%
    num_train = int(len(images) * split_ratios[0])
    num_val = int(len(images) * split_ratios[1])

    for idx, image_file in enumerate(images):
        image_path = os.path.join(image_dir, image_file)
        label_path = os.path.join(label_dir, image_file.replace(".jpg", ".txt"))

        if idx < num_train:
            split = "train"
        elif idx < num_train + num_val:
            split = "val"
        else:
            split = "test"

        shutil.move(image_path, os.path.join(base_path, "images", split, image_file))
        shutil.move(label_path, os.path.join(base_path, "labels", split, image_file.replace(".jpg", ".txt")))

# Process all datasets
for dataset in datasets:
    split_data(f"./datasets/{dataset}")

print("Datasets merged successfully.")
