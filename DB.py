import pymssql

# 直接找管理员权限！
from matplotlib import pyplot as plt, cm

connect = pymssql.connect(host='localhost', server='LAPTOP-IS2KHG9B', port='1433', user='sa', password='123456',
                          database='GlobalToyz')

if connect:
    print("数据库连接成功")
else:
    print("连接失败")

cursor = connect.cursor()
sqlQuery = "select * from City_Brand"

results = []
try:
    cursor.execute(sqlQuery)
    results = cursor.fetchall()
    print(results)
    print(len(results))  # 多少行数据
except Exception as e:
    print(e)

connect.close()

# 城市所对应的玩具品牌名和数量
citys = []
city_brand_dict = {}
for result in results:
    city = result[0]
    brand = result[1]
    count = result[2]
    if city not in city_brand_dict:
        city_brand_dict[city] = {}
        citys.append(city)
    if brand not in city_brand_dict[city]:
        city_brand_dict[city][brand] = count
    else:
        city_brand_dict[city][brand] += count

print(city_brand_dict)
print(citys)

# 获取第一个城市所对应的玩具品牌名和数量
city, brands_dict = None, {}
if results:
    city = results[0][0]
for row in results:
    if row[0] != city:
        break
    brand, count = row[1], row[2]
    brands_dict[brand] = count

# 绘制扇形图
plt.rcParams['font.family'] = ['SimSun']
fig, ax = plt.subplots(figsize=(6, 6))
ax.pie(brands_dict.values(), labels=brands_dict.keys(), autopct='%1.1f%%')
ax.set_title(f'{city} 城市的玩具品牌分布')
plt.legend()
plt.show()

# 获取第二个城市所对应的玩具品牌名和数量
brands_dict2 = {}
city2 = citys[1]
for row in results:
    if row[0] == city:   # 说明是第一个城市的数据
        continue
    elif row[0] != city2:
        break
    brand, count = row[1], row[2]
    brands_dict2[brand] = count

# 绘制扇形图
fig, ax = plt.subplots(figsize=(7, 7))
ax.pie(brands_dict2.values(), labels=brands_dict2.keys(), autopct='%1.1f%%')
ax.set_title(f'{city2} 城市的玩具品牌分布')
plt.legend()
plt.show()


# 获取第三个城市所对应的玩具品牌名和数量
brands_dict3 = {}
city3 = citys[2]
for row in results:
    if row[0] == city:   # 说明是第一个城市的数据
        continue
    elif row[0] == city2:
        continue
    elif row[0] != city3:
        break
    brand, count = row[1], row[2]
    brands_dict3[brand] = count

# 绘制扇形图
fig, ax = plt.subplots(figsize=(7, 7))
ax.pie(brands_dict3.values(), labels=brands_dict3.keys(), autopct='%1.1f%%')
ax.set_title(f'{city3} 城市的玩具品牌分布')
plt.legend()
plt.show()


# 获取第四个城市所对应的玩具品牌名和数量
brands_dict4 = {}
city4 = citys[3]
for row in results:
    if row[0] == city:   # 说明是第一个城市的数据
        continue
    elif row[0] == city2:
        continue
    elif row[0] == city3:
        continue
    elif row[0] != city4:
        break
    brand, count = row[1], row[2]
    brands_dict4[brand] = count

# 绘制扇形图
fig, ax = plt.subplots(figsize=(7, 7))
ax.pie(brands_dict4.values(), labels=brands_dict4.keys(), autopct='%1.1f%%')
ax.set_title(f'{city4} 城市的玩具品牌分布')
plt.legend()
plt.show()


# 获取第五个城市所对应的玩具品牌名和数量
brands_dict5 = {}
city5 = citys[4]
for row in results:
    if row[0] == city:   # 说明是第一个城市的数据
        continue
    elif row[0] == city2:
        continue
    elif row[0] == city3:
        continue
    elif row[0] == city4:
        continue
    elif row[0] != city5:
        break
    brand, count = row[1], row[2]
    brands_dict5[brand] = count

# 绘制扇形图
fig, ax = plt.subplots(figsize=(7, 7))
ax.pie(brands_dict5.values(), labels=brands_dict5.keys(), autopct='%1.1f%%')
ax.set_title(f'{city5} 城市的玩具品牌分布')
plt.legend()
plt.show()
