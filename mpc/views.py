from django.http import HttpResponse
from django.shortcuts import render

# def home(request):
#     return HttpResponse("Hello, you are at the default home page.")

def home(request):
    return render(request, 'polls/home.html')
