#include <stdio.h>
#include <string.h>

#define MOD (100000007);
typedef long long ll;

ll dp[6][100001];

ll divide(char prev, int count)
{
    int limit;
    ll ans;
    
    limit = 5;
    
    if (prev == '0' || prev == '8'){
        limit = 3;
    }
    
    ans = 0;
    
    while (count > 0){
        ans = (ans + dp[limit][count]) % MOD;
        count -= limit;
    }
    
    return (ans);
}

int main()
{
	static char str[100001];
	int i, j;
	int count;
	char prev;
	ll ans;
	
    dp[3][0] = dp[5][0] = 1;
    
    for (i = 1; i <= 100000; i++){
        for (j = 1; j <= 5; j++){
            if (i - j >= 0){
                dp[5][i] = (dp[5][i] + dp[5][i - j]) % MOD;
            }
        }
        for (j = 1; j <= 3; j++){
            if (i - j >= 0){
                dp[3][i] = (dp[3][i] + dp[3][i - j]) % MOD;
            }
        }
    }
    
	while (1){
		scanf("%s", str);
		if (str[0] == '#'){
			break;
		}
		
		ans = 1;
		prev = str[0];
		count = 1;
		i = 1;
		
		while (str[i] != '\0'){
			if (str[i] == prev){
				count++;
			}
			else {
				ans = (ans * divide(prev, count)) % MOD;
				prev = str[i];
				count = 1;
			}
			i++;
		}
        
		ans = (ans * divide(prev, count)) % MOD;
		printf("%lld\n", ans);
	}
	return (0);
}