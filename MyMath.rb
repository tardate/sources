class Integer

  # @see project euler #15,20,34
  def factorial
    (2..self).inject(1) { |prod, n| prod * n }
  end

  # sum of digits in the number, expressed as a decimal
  # @see project euler #16, 20
  def sum_digits
    self.to_s.split('').inject(0) { |memo, c| memo + c.to_i }
  end

  # num of digits in the number, expressed as a decimal
  # @see project euler #25
  def num_digits
    self.to_s.length
  end
  
  # returns an array of all the base10 digit rotations of the number
  # @see project euler #35
  def rotations
    self.to_s.rotations.collect { |s| s.to_i }
  end

  # tests if all the base10 digits in the number are odd
  # @see project euler #35
  def all_digits_odd?
    self.to_s.split('').inject(0) { |memo, s| memo + ( s.to_i%2==0 ? 1 : 0 ) } == 0
  end
  
  # @see project euler #4, 36, 91
  def palindrome?(base = 10)
    case base 
    when 2
      sprintf("%0b",self).palindrome?
    else
      self.to_s.palindrome?
    end
  end
  
  # http://en.wikipedia.org/wiki/Prime_factor
  # @see project euler #12
  def prime_factors
    primes = Array.new
    d = 2  
    n = self      
    while n > 1
    	if n%d==0
        primes << d
        n/=d
      else
        d+=1
      end
    end
    primes
  end
  
  # http://en.wikipedia.org/wiki/Divisor_function
  # @see project euler #12
  def divisor_count
    primes = self.prime_factors
    primes.uniq.inject(1) { |memo, p| memo * ( ( primes.find_all {|i| i == p} ).length + 1) }
  end
  
  #
  # @see project euler #12, 21, 23
  def divisors
    d = Array.new
    (1..self-1).each { |n| d << n if self % n == 0 }
    d
  end

  # @see project euler #
  def prime?
    divisors.length == 1 # this is a brute force check
  end
  
  # prime series up to this limit, using Sieve of Eratosthenes method
  # http://en.wikipedia.org/wiki/Sieve_of_Eratosthenes
  # @see project euler #7, 10, 35
  def prime_series
    t = self
    limit = Math.sqrt(t)
    @a = (2..t).to_a
    n = 2
    while (n < limit) do
      x = n*2
      begin
        @a[x-2]=2
        x+=n
      end until (x > t )
      begin
        n+=1
      end until ( @a[n-2] != 2 )
    end
    @a.uniq!
  end

  # @see project euler #23
  def perfect?
    self == divisors.sum
  end

  # @see project euler #23
  def deficient?
    self > divisors.sum
  end

  # @see project euler #23
  def abundant?
    self < divisors.sum
  end
    
  # http://en.wikipedia.org/wiki/Collatz_conjecture
  # @see project euler #14
  def collatz_series
    @a = Array.new
    @a << n = self
    while n > 1
      if n % 2 == 0
        n /= 2
      else
        n = 3*n + 1
      end
      @a << n
    end
    @a  
  end

  # express integer as an english phrase
  # @see project euler #17
  def speak
    case
    when self <20
      ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
       "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen" ][self]
    when self > 19 && self < 100 
      a = ["twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"][self / 10 - 2]
      r = self % 10
      if r == 0
        a
      else
        a + "-" + r.speak
      end
    when self > 99 && self < 1000
      a = (self / 100).speak + " hundred"
      r = self % 100
      if r == 0
        a
      else
        a + " and " + r.speak
      end      
    when self > 999 && self < 10000
      a = (self / 1000).speak + " thousand"
      r = self % 1000
      if r == 0
        a
      else
        a + ( r <100 ? " and " : " " ) + r.speak
      end      
    else
      self
    end
  end

  # generates triangle number for this integer
  # @see project euler #42
  def triangle
    self * ( self + 1 ) / 2
  end

  # calculates integer partitions for given number using array of elements 
  # http://en.wikipedia.org/wiki/Integer_partition
  # @see project euler #31
  def integer_partitions(pArray, p=0)
    if p==pArray.length-1
      1
    else
      self >= 0 ? (self - pArray[p]).integer_partitions(pArray ,p) + self.integer_partitions(pArray,p+1) : 0
    end
  end
      
end

class Array

  # sum elements in the array
  def sum
    self.inject(0) { |sum, n| sum + n }
  end
  
  # sum of squares for elements in the array
  # @see project euler #6
  def sum_of_squares
    self.inject(0) { |sos, n| sos + n**2 }
  end
  
  # @see project euler #17
  def square_of_sum
    ( self.inject(0) { |sum, n| sum + n } ) ** 2
  end
    
  # index of the smallest item in the array
  def index_of_smallest
    value, index  = self.first, 0
    self.each_with_index {| obj, i | value, index = obj, i if obj<value  }
    index
  end

  # removes numbers from the array that are factors of other elements in the array
  # @see project euler #5
  def remove_factors
    @a=Array.new
    self.each do | x | 
      @a << x if 0 == ( self.inject(0) { | memo, y | memo + (x!=y && y%x==0 ? 1 : 0)  } )
    end
    @a
  end

  # http://utilitymill.com/edit/GCF_and_LCM_Calculator
  # @see project euler #5
  def GCF
    t_val = self[0]
    for cnt in 0...self.length-1
      num1 = t_val
      num2 = self[cnt+1]
      num1,num2=num2,num1 if num1 < num2
      while num1 - num2 > 0
        num3 = num1 - num2 
        num1 = [num2,num3].max
        num2 = [num2,num3].min
      end
      t_val = num1
    end
    t_val
  end

  # http://utilitymill.com/edit/GCF_and_LCM_Calculator
  # @see project euler #5
  def LCM
    a=self.remove_factors
    t_val = a[0]
    for cnt in 0...a.length-1
      num1 = t_val
      num2 = a[cnt+1]
      tmp = [num1,num2].GCF
      t_val = tmp * num1/tmp * num2/tmp
    end
    t_val  
  end

  # brute force method:
  # http://www.cut-the-knot.org/Curriculum/Arithmetic/LCM.shtml
  # @see project euler #5
  def lcm2
    a=self.remove_factors
    c=a.dup
    while c.uniq.length>1
      index  = c.index_of_smallest  
      c[index]+=a[index]
    end
    c.first
  end

  # returns the kth Lexicographical permutation of the elements in the array
  # http://en.wikipedia.org/wiki/Permutation#Lexicographical_order_generation
  # @see project euler #24
  def lexicographic_permutation(k)
    k -= 1
    @s = self.dup
    n = @s.length
    n_less_1_factorial = (n - 1).factorial # compute (n - 1)!
    
    (1..n-1).each do |j|
      tempj = (k / n_less_1_factorial) % (n + 1 - j)

      @s[j-1..j+tempj-1]=@s[j+tempj-1,1]+@s[j-1..j+tempj-2] unless tempj==0
      n_less_1_factorial = n_less_1_factorial / (n- j)
    end
    @s
  end
  
  # returns ordered array of all the lexicographic permutations of the elements in the array
  # http://en.wikipedia.org/wiki/Permutation#Lexicographical_order_generation
  # @see project euler #24
  def lexicographic_permutations
    @a=Array.new
    (1..self.length.factorial).each { |i| @a << self.lexicographic_permutation(i) }
    @a
  end
    
end

class String

  # sum of digits in the number
  # @see project euler #16, 20
  def sum_digits
    self.split('').inject(0) { |memo, c| memo + c.to_i }
  end

  # product of digits in the number
  # @see project euler #8
  def product_digits
    self.split('').inject(1) { |memo, c| memo * c.to_i }
  end
  
  #
  # @see project euler #4, 36, 91
  def palindrome?
    self==self.reverse
  end 

  # returns an array of all the character rotations of the string
  # @see project euler #35
  def rotations
    s = self
    @rotations = Array[s]
    (1..s.length-1).each do |i|
      s=s[1..s.length-1]+s[0,1]
      @rotations << s
    end
    @rotations
  end
    
end
