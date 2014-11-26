from django.http import HttpResponse

def home(request):
    return HttpResponse('Say hello to Django!')
