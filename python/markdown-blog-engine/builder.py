import markdown

def build_blog():
    html = markdown.markdown('# Hello Blog')
    print(html)

if __name__ == '__main__':
    build_blog()