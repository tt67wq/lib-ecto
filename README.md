# LibEcto

LibEcto 是一个为 [Ecto](https://hexdocs.pm/ecto/Ecto.html) 提供的简单封装库，让日常数据库操作变得更加便捷。

## 为什么选择 LibEcto

Ecto 是一个很棒的库，但在日常使用中可能显得有些冗长。例如，假设你有一个这样的 Schema：

```elixir
defmodule Sample.Schema do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "test" do
    field :name, :string
    field :value, :string

    timestamps()
  end

  def changeset(m, params) do
    m
    |> cast(params, [:name, :value])
  end
end
```

对于大多数常见用例，你需要编写大量样板代码来进行简单的 CRUD 操作：

```elixir
defmodule Sample.DB do
  alias Sample.Schema
  alias Sample.Repo
  import Ecto.Changeset

  def insert_one(params) do
    Schema.changeset(%Schema{}, params)
    |> Repo.insert()
  end

  def update_one(m, params) do
    m
    |> change(params)
    |> Repo.update()
  end

  def delete_one(m) do
    Repo.delete(m)
  end

  def get_by_id(id) do
    Repo.get(Schema, id, select: [:id, :name, :value])
  end

  def get_by_id_array(id_array) do
    Repo.all(from m in Schema, where: m.id in ^id_array, select: [:id, :name, :value])
  end

  def get_by_name(name) do
    Repo.get_by(Schema, name: name, select: [:id, :name, :value])
  end

  #... 更多样板代码
  # - get by name array
  # - get by page
  # - get by prefix
end
```

但是！使用 LibEcto，你可以这样写：

```elixir
defmodule Sample.DB do
  use LibEctoV2

  @repo Sample.Repo
  @schema Sample.Schema
  @columns [:id, :name, :value]
  @filters [:id, :name]

  def filter(:id, dynamic, %{"id" => value}) when is_bitstring(value),
    do: {:ok, dynamic([m], ^dynamic and m.id == ^value)}

  def filter(:id, dynamic, %{"id" => value}) when is_list(value),
    do: {:ok, dynamic([m], ^dynamic and m.id in ^value)}

  def filter(:name, dynamic, %{"name" => value}) when is_bitstring(value),
    do: {:ok, dynamic([m], ^dynamic and m.name == ^value)}

  def filter(:name, dynamic, %{"name" => {"like", value}}) when is_bitstring(value),
    do: {:ok, dynamic([m], ^dynamic and like(m.name, ^value))}

  def filter(:name, dynamic, %{"name" => value}) when is_list(value),
    do: {:ok, dynamic([m], ^dynamic and m.name in ^value)}

  def filter(_, dynamic, _), do: {:ok, dynamic}

  def init_filter, do: dynamic([m], true)

  # 如果 GenericDB 无法满足你的需求，你仍然可以使用 ecto 的能力来构建复杂查询、更新或事务
  def other_complicated_query_or_update() do
    # 执行一些复杂操作
  end
end
```

LibEcto 会为你生成所有样板代码，让你可以专注于业务逻辑：

```elixir
iex> Sample.DB.create_one(%{name: "test", value: "testv"})
{:ok, %Sample.Schema{id: "2JIebKci1ZgKenvhllJa3PMbydB", name: "test", value: "testv"}}

iex> Sample.DB.get_one(%{"name" => "test"})
{:ok, %Sample.Schema{id: "2JIebKci1ZgKenvhllJa3PMbydB", name: "test", value: "testv"}}

iex> Sample.DB.get_one(%{"name" => "not-exists"})
{:ok, nil}

iex> Sample.DB.get_one!(%{"name" => "not-exists"})
** (LibEcto.Exception) not found: %{"name" => "not-exists"}

iex> {:ok, m} = Sample.DB.get_one(%{"name" => "test"})
iex> Sample.DB.update_one(m, %{name: "test2"})
{:ok, %Sample.Schema{id: "2JIebKci1ZgKenvhllJa3PMbydB", name: "test2", value: "testv"}}
```

## 支持的函数

### 写入操作
- `create_one/1` - 创建单条记录
- `update_one/2` - 更新单条记录
- `delete_one/1` - 删除单条记录
- `delete_all/1` - 删除所有匹配的记录

### 读取操作
- `get_one/2` - 获取单条记录（支持指定列）
- `fetch_one/2` - 获取单条记录，不存在时返回错误
- `get_one!/2` - 获取单条记录，不存在时抛出异常
- `get_all/2` - 获取所有匹配的记录
- `get_limit/4` - 获取有限数量的记录（支持排序）
- `get_by_page/5` - 分页获取记录
- `exists?/1` - 检查记录是否存在
- `count/1` - 计算匹配记录的数量

## V2 版本特性

V2 是 LibEcto 的完全重写版本，它更加强大和灵活。它将原来复杂的宏分解为更合理的结构。主要改进包括：

### 更清晰的架构
- 模块化的设计，职责分离
- 更好的类型安全性和错误处理
- 支持自定义过滤器和验证器

### 更灵活的配置
- 支持动态查询条件构建
- 可配置的列选择和过滤器
- 支持复杂的查询逻辑

### 更好的开发体验
- 自动生成类型定义
- 统一的错误处理机制
- 详细的文档和示例

## 安装

在 `mix.exs` 中添加 `lib_ecto` 到依赖列表：

```elixir
def deps do
  [
    {:lib_ecto, "~> 0.3"}
  ]
end
```

## 使用示例

### 基本用法

```elixir
defmodule MyApp.UserDB do
  use LibEctoV2

  @repo MyApp.Repo
  @schema MyApp.User
  @columns [:id, :name, :email, :age]
  @filters [:id, :name, :email, :age]

  # 定义过滤器
  def filter(:id, dynamic, %{"id" => id}) when is_binary(id),
    do: {:ok, dynamic([u], ^dynamic and u.id == ^id)}

  def filter(:name, dynamic, %{"name" => name}) when is_binary(name),
    do: {:ok, dynamic([u], ^dynamic and u.name == ^name)}

  def filter(:email, dynamic, %{"email" => email}) when is_binary(email),
    do: {:ok, dynamic([u], ^dynamic and u.email == ^email)}

  def filter(:age, dynamic, %{"age" => age}) when is_integer(age),
    do: {:ok, dynamic([u], ^dynamic and u.age == ^age)}

  def filter(:age, dynamic, %{"age" => {"gt", min}}) when is_integer(min),
    do: {:ok, dynamic([u], ^dynamic and u.age > ^min)}

  def filter(:age, dynamic, %{"age" => {"lt", max}}) when is_integer(max),
    do: {:ok, dynamic([u], ^dynamic and u.age < ^max)}

  def filter(_, dynamic, _), do: {:ok, dynamic}

  def init_filter, do: dynamic([u], is_nil(u.deleted_at))
end
```

### 高级用法

```elixir
# 创建用户
{:ok, user} = MyApp.UserDB.create_one(%{
  name: "John Doe",
  email: "john@example.com",
  age: 30
})

# 获取用户
{:ok, user} = MyApp.UserDB.get_one(%{"email" => "john@example.com"})

# 分页获取用户
{:ok, %{list: users, total: total}} = MyApp.UserDB.get_by_page(
  %{"age" => {"gt", 25}},  # 条件：年龄大于25
  1,                       # 第1页
  10,                      # 每页10条
  [:id, :name, :email],   # 只选择这些列
  [desc: :created_at]     # 按创建时间降序
)

# 检查用户是否存在
exists = MyApp.UserDB.exists?(%{"name" => "John Doe"})

# 统计用户数量
{:ok, count} = MyApp.UserDB.count(%{"age" => {"lt", 40}})

# 更新用户
{:ok, updated_user} = MyApp.UserDB.update_one(user, %{age: 31})

# 删除用户
{:ok, _} = MyApp.UserDB.delete_one(user)
```

## 测试

测试用例使用 [ecto_sqlite3](https://github.com/elixir-sqlite/ecto_sqlite3) 作为数据库。

运行测试：

```bash
mix test
```

测试覆盖率：

```bash
mix coveralls
```

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License