from django.urls import include, path, re_path
from django.contrib import admin
from . import views

urlpatterns = [
    path('polls/', include('polls.urls')),
    path('admin/', admin.site.urls),
    re_path('^$', views.home, name='home'),
]
