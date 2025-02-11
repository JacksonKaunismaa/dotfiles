#!/usr/bin/env python3
import torch
x = torch.rand(2, 3, 100, 100).cuda()
k = torch.rand(6, 3, 5, 5).cuda()

torch.nn.functional.conv2d(x,k)
print("Good")
