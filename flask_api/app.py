import torch
from flask import Flask, jsonify, request
from flask_cors import CORS
from torch.utils.data import RandomSampler, Sampler

app = Flask(__name__)
CORS(app)  # 這會為所有路由添加CORS支持

# 假設這是你的 PyTorch 模型架構
import torch.nn as nn
from transformers import AutoModel, PreTrainedTokenizerFast, AutoTokenizer


class CustomModel(nn.Module):
    def __init__(self, **kwargs):
        super(CustomModel, self).__init__()
        self.model = AutoModel.from_pretrained(output_hidden_states=True, return_dict=True, **kwargs)
        self.fc1 = nn.Linear(768, 3)
        self.softmax = nn.Softmax(dim=1)

    def forward(self, *args, **kwargs):
        output = self.model(**kwargs).last_hidden_state[:, 0, :]
        output = self.fc1(output)
        # output = self.softmax(output)
        return output


# 初始化模型和載入檢查點
device = torch.device('cuda')
model = CustomModel(pretrained_model_name_or_path='bert-base-cased')
model.to(device)
checkpoint = torch.load('./bert_beetle_3way_checkpoint.pth', map_location=device)
model.load_state_dict(checkpoint['model_state_dict'])
model.eval()
tokenizer = AutoTokenizer.from_pretrained('bert-base-cased')

def data_preprocess(reference_answer: str, student_answer: str, tokenizer: PreTrainedTokenizerFast):
    tokenized = tokenizer(reference_answer, student_answer, padding='max_length',
                          max_length=110, truncation=True)
    return tokenized


@app.route('/api/predict', methods=['POST'])
def predict():
    # 從 POST 請求中獲取參考答案和學生回答
    data = request.json

    reference_answer = data['reference_answer']
    student_answer = data['student_answer']

    # 轉為 PyTorch tensor
    input_data = data_preprocess(reference_answer, student_answer, tokenizer)
    input_data = {key: torch.tensor([value]).to(device) for key, value in input_data.items()}
    # 進行模型推論
    with torch.no_grad():
        output = model(**input_data)
    pred = torch.argmax(output, dim=1)
    label_map = {}
    unique_labels_num = 3
    if unique_labels_num == 2:
        label_map = ['correct', 'incorrect']
    elif unique_labels_num == 3:
        label_map = ['correct', 'incorrect', 'contradictory']
    elif unique_labels_num == 5:
        label_map = ['correct', 'contradictory', 'partially_correct_incomplete',
                     'irrelevant', 'non_domain']

    # 將預測結果轉為 Python 基本數據類型，然後返回
    return jsonify({"predicted": label_map[pred[0]]})


if __name__ == '__main__':
    app.run()
